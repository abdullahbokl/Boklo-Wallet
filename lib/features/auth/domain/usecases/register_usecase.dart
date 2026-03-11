import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

class RegisterParams {
  final String email;
  final String password;
  RegisterParams({required this.email, required this.password});
}

@injectable

/// Use case for user registration.
class RegisterUseCase implements UseCase<User, RegisterParams> {
  RegisterUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.register(params.email, params.password);
  }
}
