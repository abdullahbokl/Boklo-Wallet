import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';

/// Interface for authentication repository.
abstract class AuthRepository {
  Future<Result<User>> login(String email, String password);
  Future<Result<void>> logout();
  Future<Result<User?>> getCurrentUser();
}
