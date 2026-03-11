import 'package:equatable/equatable.dart';

enum NotificationStatus {
  pending,
  sent,
  failed,
  read,
}

class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.data,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final NotificationStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        status,
        createdAt,
        data,
      ];
}
