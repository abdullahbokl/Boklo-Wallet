import 'package:boklo/features/notification_preferences/domain/entity/notification_preference_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preference_state.freezed.dart';

@freezed
class NotificationPreferenceState with _$NotificationPreferenceState {
  const factory NotificationPreferenceState({
    @Default(NotificationPreferenceEntity())
    NotificationPreferenceEntity preferences,
    @Default(false) bool isUpdating,
  }) = _NotificationPreferenceState;
}
