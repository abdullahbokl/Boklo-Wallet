import 'package:boklo/features/notifications/data/models/notification_model.dart';

abstract class AppNotificationRemoteDataSource {
  Stream<List<NotificationModel>> observeNotifications(String userId);
  Future<void> updateNotificationStatus(String notificationId, String status);
  Future<void> deleteNotification(String notificationId);
}
