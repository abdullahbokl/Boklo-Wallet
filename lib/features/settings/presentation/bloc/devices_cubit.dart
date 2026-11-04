import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/settings/domain/entities/device_session.dart';
import 'package:boklo/features/settings/domain/repositories/session_repository.dart';
import 'package:injectable/injectable.dart';

/// Loads the device list and performs "sign out everywhere".
@injectable
class DevicesCubit extends BaseCubit<List<DeviceSession>> {
  DevicesCubit(this._repository) : super(const BaseState.initial());

  final SessionRepository _repository;

  Future<void> load() async {
    await runBlocCatching<List<DeviceSession>>(
      action: _repository.listDevices,
    );
  }

  /// Returns true when the revoke succeeded (caller then signs out).
  Future<bool> revokeAll() async {
    final result = await _repository.revokeAllSessions();
    return result.fold(
      (error) {
        emitError(error);
        return false;
      },
      (_) => true,
    );
  }
}
