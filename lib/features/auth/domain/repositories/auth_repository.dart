import 'package:boklo/core/utils/result.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';

// ignore: one_member_abstracts
abstract class AuthRepository {
  Future<Result<User>> login(String email, String password);
}
