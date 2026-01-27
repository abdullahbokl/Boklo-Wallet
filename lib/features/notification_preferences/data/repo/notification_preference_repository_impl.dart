import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/notification_preferences/data/model/notification_preference_model.dart';
import 'package:boklo/features/notification_preferences/domain/entity/notification_preference_entity.dart';
import 'package:boklo/features/notification_preferences/domain/repo/notification_preference_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: NotificationPreferenceRepository)
class NotificationPreferenceRepositoryImpl
    implements NotificationPreferenceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationPreferenceRepositoryImpl(this._firestore, this._auth);

  @override
  Stream<Result<NotificationPreferenceEntity>> watchPreferences() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(Failure(const UnknownError('User not logged in')));
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('notifications')
        .snapshots()
        .transform(StreamTransformer<DocumentSnapshot<Map<String, dynamic>>,
            Result<NotificationPreferenceEntity>>.fromHandlers(
          handleData: (snapshot, sink) {
            try {
              if (!snapshot.exists || snapshot.data() == null) {
                // Default preferences if doc doesn't exist
                sink.add(Success(const NotificationPreferenceEntity()));
              } else {
                final model =
                    NotificationPreferenceModel.fromJson(snapshot.data()!);
                sink.add(Success(model.toEntity()));
              }
            } catch (e) {
              sink.add(Failure(UnknownError(e.toString())));
            }
          },
          handleError: (error, stack, sink) {
            sink.add(Failure(UnknownError(error.toString())));
          },
        ));
  }

  @override
  Future<Result<void>> updatePreferences(
      NotificationPreferenceEntity preferences) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Failure(const UnknownError('User not logged in'));
    }

    try {
      final model = NotificationPreferenceModel.fromEntity(preferences);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('notifications')
          .set(model.toJson(), SetOptions(merge: true));
      return Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}
