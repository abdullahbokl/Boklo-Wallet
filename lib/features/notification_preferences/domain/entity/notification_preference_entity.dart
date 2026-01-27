import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preference_entity.freezed.dart';

@freezed
class NotificationPreferenceEntity with _$NotificationPreferenceEntity {
  const factory NotificationPreferenceEntity({
    @Default(true) bool enableIncoming,
    @Default(true) bool enableOutgoing,
  }) = _NotificationPreferenceEntity;
}
