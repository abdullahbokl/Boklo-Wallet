import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@injectable

/// Use case for user registration.
class RegisterUseCase {
  RegisterUseCase(this.repository);

  final AuthRepository repository;

  Future<Result<User>> call(String email, String password) {
    return repository.register(email, password);
  }
}
