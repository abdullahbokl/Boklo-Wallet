import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/notification_preferences/domain/entity/notification_preference_entity.dart';

abstract class NotificationPreferenceRepository {
  Stream<Result<NotificationPreferenceEntity>> watchPreferences();
  Future<Result<void>> updatePreferences(
      NotificationPreferenceEntity preferences);
}
