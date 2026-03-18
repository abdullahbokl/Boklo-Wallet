import 'dart:developer';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';

abstract class UserRemoteDataSource {
  Future<UserModel?> getUser(String uid);
  Future<void> setUserProfile({required String username, String? name});
  Future<void> deleteAccount();
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
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        log(
          '⚠️ getUser denied for uid=$uid. '
          'Likely unauthenticated Firestore request or App Check/API enforcement. '
          'Falling back to FirebaseAuth user.',
        );
        return null;
      }
      if (e.code == 'unavailable') {
        throw const NetworkFailure('Unable to reach profile service');
      }
      throw UnknownFailure('Failed to fetch user profile: ${e.code}');
    } catch (e) {
      throw UnknownFailure('Failed to fetch user profile: $e');
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
        log('   - Host: ${EmulatorConfig.resolvedHost}:${EmulatorConfig.functionsPort}');
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
        throw const ValidationFailure('Username is already taken');
      } else if (e.code == 'invalid-argument') {
        throw ValidationFailure(e.message ?? 'Invalid username');
      } else if (e.code == 'not-found') {
        // Task C: Improve error mapping for NOT_FOUND
        throw const UnknownFailure(
          'Profile record missing on backend. '
          '(Trigger failure or manual sync needed)',
        );
      } else if (e.code == 'failed-precondition' ||
          e.code == 'permission-denied') {
        throw const ServerFailure(
          'Request blocked by backend security rules or function '
          'preconditions.',
        );
      } else if (e.code == 'unauthenticated') {
        throw const ServerFailure(
          'Your session expired. Please sign in again.',
        );
      } else if (e.code == 'unavailable') {
        throw const NetworkFailure('Unable to reach profile service');
      }
      throw UnknownFailure('Profile update failed: ${e.code}');
    } catch (e) {
      log('❌ setUserProfile Unexpected Error: $e');
      throw UnknownFailure('Profile update failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call<Map<String, dynamic>>();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        throw ValidationFailure(e.message ?? 'Account deletion is not allowed.');
      } else if (e.code == 'unauthenticated') {
        throw const ServerFailure('Your session expired. Please sign in again.');
      } else if (e.code == 'unavailable') {
        throw const NetworkFailure('Unable to reach account deletion service');
      }
      throw UnknownFailure(e.message ?? 'Failed to delete account');
    } catch (e) {
      throw UnknownFailure('Failed to delete account: $e');
    }
  }
}
