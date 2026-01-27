import 'package:boklo/features/notification_preferences/domain/entity/notification_preference_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preference_model.freezed.dart';
part 'notification_preference_model.g.dart';

@freezed
class NotificationPreferenceModel with _$NotificationPreferenceModel {
  const NotificationPreferenceModel._();

  const factory NotificationPreferenceModel({
    @Default(true) bool enableIncoming,
    @Default(true) bool enableOutgoing,
  }) = _NotificationPreferenceModel;

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferenceModelFromJson(json);

  NotificationPreferenceEntity toEntity() {
    return NotificationPreferenceEntity(
      enableIncoming: enableIncoming,
      enableOutgoing: enableOutgoing,
    );
  }

  static NotificationPreferenceModel fromEntity(
      NotificationPreferenceEntity entity) {
    return NotificationPreferenceModel(
      enableIncoming: entity.enableIncoming,
      enableOutgoing: entity.enableOutgoing,
    );
  }
}
