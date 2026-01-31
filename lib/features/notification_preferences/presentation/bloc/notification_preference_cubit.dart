import 'dart:async';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/notification_preferences/domain/entity/notification_preference_entity.dart';
import 'package:boklo/features/notification_preferences/domain/repo/notification_preference_repository.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class NotificationPreferenceCubit
    extends BaseCubit<NotificationPreferenceState> {
  final NotificationPreferenceRepository _repository;
  StreamSubscription<Result<NotificationPreferenceEntity>>? _sub;

  NotificationPreferenceCubit(this._repository)
      : super(const BaseState.initial());

  void init() {
    emitLoading();
    _sub?.cancel();
    _sub = _repository.watchPreferences().listen((result) {
      result.fold(
        (error) => emitError(error),
        (data) {
          final current = state.data ?? const NotificationPreferenceState();
          emitSuccess(current.copyWith(preferences: data));
        },
      );
    });
  }

  Future<void> toggleIncoming(bool value) async {
    final current = state.data ?? const NotificationPreferenceState();
    final previousPrefs = current.preferences;
    final newPrefs = previousPrefs.copyWith(enableIncoming: value);

    // Optimistic Update: Update UI immediately
    emitSuccess(current.copyWith(
      preferences: newPrefs,
      isUpdating: true,
    ));

    final result = await _repository.updatePreferences(newPrefs);

    result.fold(
      (error) {
        // Revert on failure
        emitError(error);
        emitSuccess(current.copyWith(
          preferences: previousPrefs,
          isUpdating: false,
        ));
      },
      (_) {
        // Success: Just turn off loading, stream maintains state
        emitSuccess(current.copyWith(
            preferences: newPrefs, // Ensure it sticks
            isUpdating: false));
      },
    );
  }

  Future<void> toggleOutgoing(bool value) async {
    final current = state.data ?? const NotificationPreferenceState();
    final previousPrefs = current.preferences;
    final newPrefs = previousPrefs.copyWith(enableOutgoing: value);

    // Optimistic Update
    emitSuccess(current.copyWith(
      preferences: newPrefs,
      isUpdating: true,
    ));

    final result = await _repository.updatePreferences(newPrefs);

    result.fold(
      (error) {
        emitError(error);
        emitSuccess(current.copyWith(
          preferences: previousPrefs,
          isUpdating: false,
        ));
      },
      (_) {
        emitSuccess(current.copyWith(preferences: newPrefs, isUpdating: false));
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
