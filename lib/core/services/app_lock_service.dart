import 'dart:async';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// App-lock state + local biometric/device-credential authentication.
///
/// When enabled, the app-lock gate requires a successful local
/// authentication (biometric or device PIN/pattern) before the app content
/// becomes usable after each backgrounding of the app.
@lazySingleton
class AppLockService {
  AppLockService(this._storage, this._localAuth);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _enabledKey = 'APP_LOCK_ENABLED';

  /// Whether the lock screen is currently blocking the UI.
  bool isLocked = false;

  /// Whether the user has turned app lock on. Falls back to false on any
  /// storage failure (fail-open only for the *preference*, never for the
  /// authentication check itself).
  Future<bool> isEnabled() async {
    try {
      return await _storage.read(key: _enabledKey) == 'true';
    } on Object catch (e) {
      log('⚠️ AppLockService: failed to read preference: $e');
      return false;
    }
  }

  Future<void> setEnabled({required bool enabled}) async {
    try {
      if (enabled) {
        await _storage.write(key: _enabledKey, value: 'true');
      } else {
        await _storage.delete(key: _enabledKey);
      }
    } on Object catch (e) {
      log('⚠️ AppLockService: failed to persist preference: $e');
    }
  }

  /// Whether the device can perform a local authentication at all
  /// (biometric hardware enrolled, or device credentials available).
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      return canCheck;
    } on Object catch (e) {
      log('⚠️ AppLockService: availability check failed: $e');
      return false;
    }
  }

  /// Runs the platform local-authentication dialog.
  Future<bool> authenticate() async {
    try {
      return _localAuth.authenticate(
        localizedReason: 'Unlock Boklo to continue',
        // stickyAuth equivalent: keep the auth session alive across
        // backgrounding so the app-lock flow survives interruptions.
        persistAcrossBackgrounding: true,
      );
    } on Object catch (e) {
      log('⚠️ AppLockService: authentication error: $e');
      return false;
    }
  }
}
