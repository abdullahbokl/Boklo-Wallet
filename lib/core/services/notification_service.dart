import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/notification/fcm_token_manager.dart';
import 'package:boklo/core/services/notification/local_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

@lazySingleton
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NavigationService _navigationService;
  final FcmTokenManager _tokenManager;
  final LocalNotificationService _localNotifications;

  String? pendingRoute;

  NotificationService(
    this._navigationService,
    this._tokenManager,
    this._localNotifications,
  );

  Future<void> initialize() async {
    await _localNotifications.initialize(
        onNotificationTap: _handleNotificationTap);
    await _requestPermissions();
    await _checkInitialMessage();
    _registerForegroundHandler();
    _registerBackgroundHandler();
    await _tokenManager.syncToken();
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false);
    await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, badge: true, sound: false);
    log('User granted permission: ${settings.authorizationStatus}');
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
      _localNotifications.show(message);
    });
  }

  void _registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('App opened from background state via notification');
      _handleRemoteMessageTap(message);
    });
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
    _navigationService.push('/wallet');
  }

  void _setPendingRoute(RemoteMessage message) {
    if (message.data.containsKey('transactionId')) {
      pendingRoute = '/wallet';
    }
  }

  Future<void> deleteToken() async {
    await _tokenManager.deleteToken();
    await _localNotifications.cancelAll();
  }
}
