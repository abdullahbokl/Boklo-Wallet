import 'dart:async';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/notification_preferences/domain/repo/notification_preference_repository.dart';
import 'package:boklo/features/notification_preferences/presentation/bloc/notification_preference_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class NotificationPreferenceCubit
    extends BaseCubit<NotificationPreferenceState> {
  final NotificationPreferenceRepository _repository;
  StreamSubscription? _sub;

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
    final newPrefs = current.preferences.copyWith(enableIncoming: value);
    // Optimistic update?
    // Or wait?
    // For preferences, optimistic is good but we have stream.
    // If we update, stream will update.
    // We can show loading indicator.

    emitSuccess(current.copyWith(isUpdating: true));

    final result = await _repository.updatePreferences(newPrefs);

    result.fold(
      (error) {
        emitError(error);
        emitSuccess(current.copyWith(isUpdating: false));
        // Revert? Stream should keep it correct.
      },
      (_) {
        emitSuccess(current.copyWith(isUpdating: false));
      },
    );
  }

  Future<void> toggleOutgoing(bool value) async {
    final current = state.data ?? const NotificationPreferenceState();
    final newPrefs = current.preferences.copyWith(enableOutgoing: value);

    emitSuccess(current.copyWith(isUpdating: true));

    final result = await _repository.updatePreferences(newPrefs);

    result.fold(
      (error) {
        emitError(error);
        emitSuccess(current.copyWith(isUpdating: false));
      },
      (_) {
        emitSuccess(current.copyWith(isUpdating: false));
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
