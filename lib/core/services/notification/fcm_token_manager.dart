import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FcmTokenManager {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FcmTokenManager(this._messaging, this._auth, this._firestore);

  Future<void> syncToken() async {
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

  Future<void> deleteToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(token)
            .delete();
        log('FCM Token deleted from Firestore');
      }
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }
}
