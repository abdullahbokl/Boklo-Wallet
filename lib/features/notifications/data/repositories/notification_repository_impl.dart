import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:boklo/features/notifications/domain/repositories/app_notif_repo_domain.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AppNotificationRepository)
class AppNotificationRepositoryImpl implements AppNotificationRepository {
  AppNotificationRepositoryImpl(this._remoteDataSource, this._auth);

  final AppNotificationRemoteDataSource _remoteDataSource;
  final FirebaseAuth _auth;

  @override
  Stream<Either<Failure, List<NotificationEntity>>> observeNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(const Left(ServerFailure('User not authenticated')));
    }

    return _remoteDataSource.observeNotifications(userId).map((models) {
      try {
        final entities = models.map((m) => m.toEntity()).toList();
        return Right(entities);
      } catch (e) {
        return Left(ServerFailure('Failed to parse notifications: $e'));
      }
    });
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _remoteDataSource.updateNotificationStatus(notificationId, 'READ');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      await _remoteDataSource.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
