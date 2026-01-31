import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({
    required void Function(String?) onNotificationTap,
  }) async {
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
        onNotificationTap(response.payload);
      },
    );

    await _createNotificationChannel();
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

  void show(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      log('Showing Local Notification: ${notification.title}');

      _localNotifications.show(
        // Use a unique ID to allow multiple notifications to stack
        DateTime.now().millisecondsSinceEpoch % 100000,
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

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}
