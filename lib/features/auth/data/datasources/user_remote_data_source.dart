import 'dart:developer';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

abstract class UserRemoteDataSource {
  Future<UserModel?> getUser(String uid);
  Future<void> setUserProfile({required String username, String? name});
}

@LazySingleton(as: UserRemoteDataSource)
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw UnknownError('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<void> setUserProfile({required String username, String? name}) async {
    try {
      final callable = _functions.httpsCallable('setUserProfile');

      final isEmulator = EmulatorConfig.resolvedHost != null;
      log('🚀 Calling setUserProfile function');
      log('   - Mode: ${isEmulator ? "EMULATOR" : "PRODUCTION"}');
      if (isEmulator) {
        log('   - Host: ${EmulatorConfig.resolvedHost}:5001');
      }
      log('   - Params: username=$username, name=$name');

      final result =
          await callable.call<Map<String, dynamic>>(<String, dynamic>{
        'username': username,
        'name': name,
      });
      log('✅ setUserProfile success: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      log('❌ setUserProfile FirebaseFunctionsException: '
          '[${e.code}] ${e.message}');
      log('   - Details: ${e.details}');

      if (e.code == 'already-exists') {
        throw const ValidationError('Username is already taken');
      } else if (e.code == 'invalid-argument') {
        throw ValidationError(e.message ?? 'Invalid username');
      } else if (e.code == 'not-found') {
        // Task C: Improve error mapping for NOT_FOUND
        throw const UnknownError(
          'Profile record missing on backend. '
          '(Trigger failure or manual sync needed)',
        );
      }
      throw UnknownError('Profile update failed: ${e.code}');
    } catch (e) {
      log('❌ setUserProfile Unexpected Error: $e');
      throw UnknownError('Profile update failed: $e');
    }
  }
}
