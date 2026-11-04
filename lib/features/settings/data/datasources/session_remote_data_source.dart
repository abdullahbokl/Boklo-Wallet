import 'package:boklo/features/settings/domain/entities/device_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

/// Data source for session/device management: reads the user's FCM token
/// docs (owner-readable per rules) and drives the revoke callable.
abstract class SessionRemoteDataSource {
  Future<List<DeviceSession>> listDevices();
  Future<String?> currentDeviceToken();
  Future<void> revokeAllSessions();
}

@LazySingleton(as: SessionRemoteDataSource)
class SessionRemoteDataSourceImpl implements SessionRemoteDataSource {
  SessionRemoteDataSourceImpl(this._firestore, this._auth, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  @override
  Future<List<DeviceSession>> listDevices() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('tokens')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      return DeviceSession(
        token: doc.id,
        platform: data['platform'] as String? ?? 'unknown',
        createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      );
    }).toList();
  }

  @override
  Future<String?> currentDeviceToken() {
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> revokeAllSessions() async {
    await _functions.httpsCallable('revokeAllSessions').call<void>();
  }
}
