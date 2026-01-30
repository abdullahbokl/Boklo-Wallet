import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/login_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/register_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/set_user_profile_usecase.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthCubit extends BaseCubit<User?> {
  AuthCubit(
    this._loginUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._registerUseCase,
    this._setUserProfileUseCase,
    this._analyticsService,
    this._notificationService,
  ) : super(const BaseState.initial());

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RegisterUseCase _registerUseCase;
  final SetUserProfileUseCase _setUserProfileUseCase;
  final AnalyticsService _analyticsService;
  final NotificationService _notificationService;

  Future<void> login(String email, String password) async {
    emitLoading();
    final result = await _loginUseCase(email, password);
    result.fold(
      emitError,
      (user) {
        unawaited(_analyticsService.logLogin(method: 'email'));
        emitSuccess(user);
      },
    );
  }

  Future<void> register(String email, String password) async {
    emitLoading();
    final result = await _registerUseCase(email, password);
    result.fold(
      emitError,
      emitSuccess,
    );
  }

  Future<void> logout() async {
    emitLoading();
    await _notificationService.deleteToken();
    final result = await _logoutUseCase();
    result.fold(
      emitError,
      (_) => emitSuccess(null),
    );
  }

  Future<void> checkAuthStatus() async {
    emitLoading();
    final result = await _getCurrentUserUseCase();
    result.fold(
      emitError,
      emitSuccess,
    );
  }

  Future<void> setUserProfile({
    required String username,
    String? name,
  }) async {
    emitLoading();
    final result = await _setUserProfileUseCase(
      username: username,
      name: name,
    );
    result.fold(
      emitError,
      (_) async {
        // Refresh user to get updated fields
        await checkAuthStatus();
      },
    );
  }
}
