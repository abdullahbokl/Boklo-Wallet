import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:boklo/core/services/navigation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

@lazySingleton
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NavigationService _navigationService;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? pendingRoute;

  NotificationService(
    this._auth,
    this._firestore,
    this._navigationService,
  );

  Future<void> initialize() async {
    // 1. Initialize Local Notifications
    await _initializeLocalNotifications();

    // 2. Request Permissions
    await _requestPermissions();

    // 3. Create Android Channel
    await _createNotificationChannel();

    // 4. Handle Terminated State (Initial Message)
    await _checkInitialMessage();

    // 5. Register Listeners
    _registerForegroundHandler();
    _registerBackgroundHandler();
    _registerTokenRefreshHandler();

    // 6. Token Management
    await _syncToken();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification tapped (Foreground/Local): ${response.payload}');
        _handleNotificationTap(response.payload);
      },
    );
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Explicitly disable foreground presentation options to avoid duplicates
    // because we are showing local notifications manually.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    log('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log('App opened from terminated state via notification');
      _setPendingRoute(initialMessage);
    }
  }

  void _registerForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      showForegroundNotification(message);
    });
  }

  void _registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('App opened from background state via notification');
      _handleRemoteMessageTap(message);
    });
  }

  void showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      log('Showing Local Notification: ${notification.title}');

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: android != null
              ? AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  channelDescription:
                      'This channel is used for important notifications.',
                  icon: android.smallIcon ?? '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                )
              : null,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _navigateFromData(data);
      } catch (e) {
        log('Error parsing notification payload: $e');
      }
    }
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    log('Navigating based on notification data: $data');
    // Example: Navigate to wallet if transactionId is present
    // You can expand this logic based on your event types
    if (data.containsKey('transactionId')) {
      _navigationService.push('/wallet');
    } else {
      // Default fallback
      _navigationService.push('/wallet');
    }
  }

  void _setPendingRoute(RemoteMessage message) {
    if (message.data.containsKey('transactionId')) {
      pendingRoute = '/wallet';
    }
  }

  Future<void> _syncToken() async {
    // Get current token
    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      await _saveTokenToFirestore(fcmToken);
    }

    // Monitor Auth State
    _auth.userChanges().listen((user) async {
      if (user != null) {
        final token = await _messaging.getToken();
        if (token != null) await _saveTokenToFirestore(token);
      }
    });

    // Monitor Token Refresh
    _registerTokenRefreshHandler();
  }

  void _registerTokenRefreshHandler() {
    _messaging.onTokenRefresh.listen((newToken) {
      log('FCM Token refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
      log('FCM Token saved to Firestore');
    } catch (e) {
      log('Error saving FCM token: $e');
    }
  }
}
