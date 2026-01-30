import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:boklo/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:injectable/injectable.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this.remoteDataSource,
    this.userRemoteDataSource,
  );

  final AuthRemoteDataSource remoteDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      // Fetch full profile from Firestore
      final profile = await userRemoteDataSource.getUser(userModel.id);
      if (profile != null) {
        return Success(profile.toEntity());
      }
      return Success(userModel.toEntity());
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e));
    } on Object catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<User>> register(String email, String password) async {
    try {
      final userModel = await remoteDataSource.register(email, password);
      // Backend creates user document via Cloud Function.
      // We don't create it client-side anymore.
      return Success(userModel.toEntity());
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
      if (userModel == null) return const Success(null);

      final profile = await userRemoteDataSource.getUser(userModel.id);
      if (profile != null) {
        return Success(profile.toEntity());
      }
      return Success(userModel.toEntity());
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
