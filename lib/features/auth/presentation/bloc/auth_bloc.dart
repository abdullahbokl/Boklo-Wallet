import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthBloc extends BaseCubit<User> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const BaseState.initial());

  Future<void> login(String email, String password) async {
    await runBlocCatching<User>(
      action: () => _repository.login(email, password),
    );
  }
}
