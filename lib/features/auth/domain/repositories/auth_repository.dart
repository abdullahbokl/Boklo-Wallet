import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';

// ignore: one_member_abstracts, justification: "Interfaces usually have few members."
abstract class AuthRepository {
  Future<Result<User>> login(String email, String password);
  Future<Result<void>> logout();
  Future<Result<User?>> getCurrentUser();
}
