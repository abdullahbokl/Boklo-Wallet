import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/notification_preferences/domain/entity/notification_preference_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class NotificationPreferenceRepository {
  Stream<Either<Failure, NotificationPreferenceEntity>> watchPreferences();
  Future<Either<Failure, void>> updatePreferences(
      NotificationPreferenceEntity preferences,);
}
