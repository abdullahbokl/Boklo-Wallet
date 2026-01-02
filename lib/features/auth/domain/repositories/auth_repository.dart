import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

// ignore: one_member_abstracts
abstract class AuthRepository {
  Future<Either<AppError, User>> login(String email, String password);
}
