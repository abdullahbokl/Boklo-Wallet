import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class AppNotificationRepository {
  Stream<Either<Failure, List<NotificationEntity>>> observeNotifications();
  Future<Either<Failure, void>> markAsRead(String notificationId);
  Future<Either<Failure, void>> deleteNotification(String notificationId);
}
