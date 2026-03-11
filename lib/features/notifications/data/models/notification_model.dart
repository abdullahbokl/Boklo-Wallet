import 'package:boklo/core/utils/json_converters.dart';
import 'package:boklo/features/notifications/domain/entities/notification_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.sentAt,
  });

  final String id;
  final String userId;
  final String type;
  final NotificationPayloadModel payload;
  final String status;
  @TimestampConverter()
  final DateTime createdAt;
  @TimestampConverter()
  final DateTime? processedAt;
  @TimestampConverter()
  final DateTime? sentAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Inject ID if missing and provided as separate field in some contexts
    final map = Map<String, dynamic>.from(json);
    if (!map.containsKey('id') && map.containsKey('notificationId')) {
      map['id'] = map['notificationId'];
    }
    return _$NotificationModelFromJson(map);
  }

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationEntity toEntity() {
    // Helper to resolve title/body from keys in model
    // In a real app, we'd use localizations, but for now we follow the backend logic
    String resolvedTitle = payload.titleKey;
    String resolvedBody = payload.bodyKey;

    if (payload.titleKey == 'transfer_sent_success_title') resolvedTitle = 'Transfer Sent';
    if (payload.titleKey == 'transfer_received_title') resolvedTitle = 'Money Received';
    if (payload.titleKey == 'transfer_failed_title') resolvedTitle = 'Transfer Failed';
    if (payload.titleKey == 'payment_request_title') resolvedTitle = 'Payment Requested';

    resolvedBody = _resolveBody(payload.bodyKey, payload.data);

    return NotificationEntity(
      id: id,
      userId: userId,
      type: type,
      title: resolvedTitle,
      body: resolvedBody,
      status: _mapStatus(status),
      createdAt: createdAt,
      data: payload.data,
    );
  }

  static NotificationStatus _mapStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return NotificationStatus.pending;
      case 'SENT':
        return NotificationStatus.sent;
      case 'FAILED':
        return NotificationStatus.failed;
      default:
        return NotificationStatus.read;
    }
  }

  String _resolveBody(String key, Map<String, dynamic>? data) {
    String text = key;
    if (key == 'transfer_sent_success_body') text = 'You sent {amount} {currency}.';
    if (key == 'transfer_received_body') text = 'You received {amount} {currency}.';
    if (key == 'transfer_failed_body') text = 'Your transfer failed. {reason}';
    if (key == 'payment_request_body') text = '{requesterId} requested {amount} {currency}.';

    if (data != null) {
      data.forEach((k, v) {
        text = text.replaceAll('{$k}', v.toString());
      });
    }
    return text;
  }
}

@JsonSerializable()
class NotificationPayloadModel {
  const NotificationPayloadModel({
    required this.titleKey,
    required this.bodyKey,
    this.data,
  });

  final String titleKey;
  final String bodyKey;
  final Map<String, dynamic>? data;

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationPayloadModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPayloadModelToJson(this);
}
