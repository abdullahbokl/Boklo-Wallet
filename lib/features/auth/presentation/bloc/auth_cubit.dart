import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/login_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthCubit extends BaseCubit<User?> {
  AuthCubit(
    this._loginUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const BaseState.initial());

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> login(String email, String password) async {
    emitLoading();
    final result = await _loginUseCase(email, password);
    result.fold(
      emitError,
      emitSuccess,
    );
  }

  Future<void> logout() async {
    emitLoading();
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
}
