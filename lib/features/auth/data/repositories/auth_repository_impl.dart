import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remoteDataSource);

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Success(user);
    } on Object catch (e) {
      if (e is AppError) return Failure(e);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Success(null);
    } on Object catch (e) {
      if (e is AppError) return Failure(e);
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Success(user);
    } on Object catch (e) {
      if (e is AppError) return Failure(e);
      return Failure(UnknownError(e.toString()));
    }
  }
}
