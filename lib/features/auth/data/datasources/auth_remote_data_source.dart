import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/models/user_model.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:injectable/injectable.dart';

abstract class AuthRemoteDataSource {
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._firebaseAuth);

  final firebase_auth.FirebaseAuth _firebaseAuth;

  @override
  Future<User> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownError('User is null after login');
      }
      return UserModel.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (e) {
      throw UnknownError(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw UnknownError(e.toString());
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserModel.fromFirebaseUser(user);
    }
    return null;
  }

  AppError _mapFirebaseError(firebase_auth.FirebaseAuthException e) {
    if (e.code == 'network-request-failed') {
      return NetworkError('Network error', e);
    }
    return FirebaseError(e.message ?? 'Authentication failed', e.code, e);
  }
}
