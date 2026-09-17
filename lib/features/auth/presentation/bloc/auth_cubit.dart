import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/login_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/register_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/set_user_profile_usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthCubit extends BaseCubit<User?> {
  AuthCubit(
    this._authRepository,
    this._loginUseCase,
    this._logoutUseCase,
    this._deleteAccountUseCase,
    this._getCurrentUserUseCase,
    this._registerUseCase,
    this._setUserProfileUseCase,
    this._analyticsService,
    this._notificationService,
  ) : super(const BaseState.initial());

  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final RegisterUseCase _registerUseCase;
  final SetUserProfileUseCase _setUserProfileUseCase;
  final AnalyticsService _analyticsService;
  final NotificationService _notificationService;

  Future<void> login(String email, String password) async {
    emitLoading();
    final result = await _loginUseCase(
      LoginParams(email: email, password: password),
    );
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
    final result = await _registerUseCase(
      RegisterParams(email: email, password: password),
    );
    result.fold(
      emitError,
      emitSuccess,
    );
  }

  Future<void> logout() async {
    emitLoading();
    await _notificationService.deleteToken();
    final result = await _logoutUseCase(NoParams());
    result.fold(
      emitError,
      (_) => emitSuccess(null),
    );
  }

  Future<void> deleteAccount(String password) async {
    emitLoading();
    final result = await _deleteAccountUseCase(
      DeleteAccountParams(password: password),
    );

    await result.fold(
      (failure) async => emitError(failure),
      (_) async {
        await _notificationService.deleteToken();
        await _logoutUseCase(NoParams());
        emitSuccess(null);
      },
    );
  }

  /// Sends a password-reset email; responds uniformly to avoid account
  /// enumeration.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    return _authRepository.sendPasswordResetEmail(email);
  }

  Future<void> sendEmailVerification() async {
    await _authRepository.sendEmailVerification();
  }

  Future<void> refreshEmailVerification() async {
    final result = await _authRepository.reloadEmailVerificationStatus();
    result.fold(
      emitError,
      (verified) {
        final current = state.data;
        if (current != null && verified && !current.emailVerified) {
          emitSuccess(current.copyWith(emailVerified: true));
        }
      },
    );
  }

  Future<void> checkAuthStatus() async {
    emitLoading();
    final result = await _getCurrentUserUseCase(NoParams());
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
      SetUserProfileParams(
        username: username,
        name: name,
      ),
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
