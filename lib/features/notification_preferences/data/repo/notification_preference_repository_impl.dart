import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
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
  Stream<Either<Failure, NotificationPreferenceEntity>> watchPreferences() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const Left(ServerFailure('User not logged in')));
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('notifications')
        .snapshots()
        .transform(StreamTransformer<DocumentSnapshot<Map<String, dynamic>>,
            Either<Failure, NotificationPreferenceEntity>>.fromHandlers(
          handleData: (snapshot, sink) {
            try {
              if (!snapshot.exists || snapshot.data() == null) {
                // Default preferences if doc doesn't exist
                sink.add(const Right(NotificationPreferenceEntity()));
              } else {
                final model =
                    NotificationPreferenceModel.fromJson(snapshot.data()!);
                sink.add(Right(model.toEntity()));
              }
            } catch (e) {
              sink.add(Left(UnknownFailure(e.toString())));
            }
          },
          handleError: (error, stack, sink) {
            sink.add(Left(UnknownFailure(error.toString())));
          },
        ));
  }

  @override
  Future<Either<Failure, void>> updatePreferences(
      NotificationPreferenceEntity preferences) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Left(ServerFailure('User not logged in'));
    }

    try {
      final model = NotificationPreferenceModel.fromEntity(preferences);
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('notifications')
          .set(model.toJson(), SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
