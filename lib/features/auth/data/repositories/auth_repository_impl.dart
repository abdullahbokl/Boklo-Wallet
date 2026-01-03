import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remoteDataSource);

  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Success(user.toEntity());
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e));
    } on Object catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e));
    } on Object catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return Success(userModel?.toEntity());
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e));
    } on Object catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  AppError _mapFirebaseError(FirebaseAuthException e) {
    if (e.code == 'network-request-failed') {
      return NetworkError('Network error', e);
    }
    return FirebaseError(e.message ?? 'Authentication failed', e.code, e);
  }
}
