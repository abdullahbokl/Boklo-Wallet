import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LogoutUseCase {
  LogoutUseCase(this.repository);

  final AuthRepository repository;

  Future<Result<void>> call() => repository.logout();
}
