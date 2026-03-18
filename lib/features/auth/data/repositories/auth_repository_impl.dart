import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:boklo/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:fpdart/fpdart.dart';
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
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      // Fetch full profile from Firestore
      final profile = await userRemoteDataSource.getUser(userModel.id);
      if (profile != null) {
        return Right(profile.toEntity());
      }
      return Right(userModel.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register(String email, String password) async {
    try {
      final userModel = await remoteDataSource.register(email, password);
      // Backend creates user document via Cloud Function.
      // We don't create it client-side anymore.
      return Right(userModel.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String password) async {
    try {
      await remoteDataSource.reauthenticate(password);
      await userRemoteDataSource.deleteAccount();
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      if (userModel == null) return const Right(null);

      final profile = await userRemoteDataSource.getUser(userModel.id);
      if (profile != null) {
        return Right(profile.toEntity());
      }
      return Right(userModel.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseError(e));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Failure _mapFirebaseError(FirebaseAuthException e) {
    if (e.code == 'network-request-failed') {
      return NetworkFailure(e.message ?? 'Network error');
    }
    if (e.code == 'wrong-password' ||
        e.code == 'invalid-credential' ||
        e.code == 'requires-recent-login') {
      return const ValidationFailure(
        'Please re-enter your password to confirm account deletion.',
      );
    }
    return ServerFailure(e.message ?? 'Authentication failed');
  }
}
