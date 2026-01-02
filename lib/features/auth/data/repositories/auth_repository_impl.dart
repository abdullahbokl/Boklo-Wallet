import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remoteDataSource);

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Either<AppError, User>> login(String email, String password) async {
    try {
      // TODO(dev): Map result to User
      await remoteDataSource.login(email, password);
      return const Right(User(id: '1', email: 'test@example.com'));
    } catch (e) {
      if (e is AppError) {
        return Left(e);
      }
      return Left(UnknownError(e.toString()));
    }
  }
}
