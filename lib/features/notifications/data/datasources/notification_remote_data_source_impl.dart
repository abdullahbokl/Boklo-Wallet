import 'package:boklo/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:boklo/features/notifications/data/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AppNotificationRemoteDataSource)
class AppNotificationRemoteDataSourceImpl implements AppNotificationRemoteDataSource {
  AppNotificationRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<NotificationModel>> observeNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return NotificationModel.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<void> updateNotificationStatus(String notificationId, String status) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'status': status});
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
