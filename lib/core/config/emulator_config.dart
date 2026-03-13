import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class EmulatorConfig {
  static const int _defaultAuthPort = 9098;
  static const int _defaultFirestorePort = 8086;
  static const int _defaultFunctionsPort = 5001;
  static const int _defaultStoragePort = 9200;

  // Keep app ports configurable to avoid future firebase.json drift.
  static final int _authPort = _readPortFromEnv(
    'AUTH_EMULATOR_PORT',
    _defaultAuthPort,
  );
  static final int _firestorePort = _readPortFromEnv(
    'FIRESTORE_EMULATOR_PORT',
    _defaultFirestorePort,
  );
  static final int _functionsPort = _readPortFromEnv(
    'FUNCTIONS_EMULATOR_PORT',
    _defaultFunctionsPort,
  );
  static final int _storagePort = _readPortFromEnv(
    'STORAGE_EMULATOR_PORT',
    _defaultStoragePort,
  );

  static const String _androidEmulatorHost = '10.0.2.2';
  static const String _localhost = 'localhost';

  // Allow passing host via command line: --dart-define=EMULATOR_HOST=192.168.1.X
  static const String _envHost = String.fromEnvironment('EMULATOR_HOST');

  static String? _resolvedHost;
  static String? get resolvedHost => _resolvedHost;
  static int get functionsPort => _functionsPort;

  static Future<void> configure() async {
    final host = await _resolveHost();
    _resolvedHost = host;

    var isPhysicalAndroid = false;
    var isGenymotion = false;
    if (!kIsWeb && Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      isGenymotion = _isGenymotion(androidInfo);
      // Genymotion reports isPhysicalDevice=true, but it IS a virtual device
      isPhysicalAndroid = androidInfo.isPhysicalDevice && !isGenymotion;
    }

    log('🔥 Configuring Firebase Emulators at $host'
        '${isGenymotion ? ' (Genymotion detected)' : ''}');

    // 1. Auth (Hybrid: Real Auth on Physical, Emulator on others)
    if (isPhysicalAndroid) {
      log('⚠️ Hybrid Setup: Using REAL Firebase Auth on Physical Device');
      // Do NOT enable Auth emulator
    } else if (host != null) {
      FirebaseAuth.instance.useAuthEmulator(host, _authPort);
      FirebaseAuth.instance.setLanguageCode('en');
    } else {
      // Default fallback if somehow host is null but not physical device.
      FirebaseAuth.instance.setLanguageCode('en');
    }

    // 2. Firestore
    if (host != null) {
      FirebaseFirestore.instance.useFirestoreEmulator(host, _firestorePort);

      // 3. Functions (use explicit region to match app_module.dart)
      FirebaseFunctions.instanceFor(region: 'us-central1')
          .useFunctionsEmulator(host, _functionsPort);

      // 4. Storage
      FirebaseStorage.instance.useStorageEmulator(host, _storagePort);
    } else {
      // When running on a physical Android device without an explicit
      // EMULATOR_HOST we avoid trying to connect to emulators (which would
      // otherwise fail or time out). Informative logs tell the developer what
      // to do if they intended to use emulators from a physical device.
      log('⚠️ EMULATOR HOST NOT PROVIDED: Skipping Firestore/Functions/Storage emulator configuration.');
      log('   If you want to connect a physical device to local emulators, run:');
      log('   flutter run --dart-define=EMULATOR_HOST=YOUR_LOCAL_IP');
    }

    // 5. Force Token Reload
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } catch (e) {
        log('ℹ️ Auth State Mismatch: Signing out to clear stale token...');
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  /// Detects Genymotion by manufacturer or VirtualBox hardware.
  static bool _isGenymotion(AndroidDeviceInfo info) {
    return info.manufacturer.toLowerCase() == 'genymobile' ||
        info.hardware.toLowerCase().contains('vbox');
  }

  static const String _genymotionHost = '10.0.3.2';

  static int _readPortFromEnv(String key, int fallback) {
    final raw = String.fromEnvironment(key);
    if (raw.isEmpty) {
      return fallback;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0 || parsed > 65535) {
      log('⚠️ Invalid $key="$raw"; falling back to $fallback');
      return fallback;
    }
    return parsed;
  }

  static Future<String?> _resolveHost() async {
    // 1. If host is explicitly provided via env (e.g. for physical device testing), use it.
    if (_envHost.isNotEmpty) {
      log('🔥 Using explicit emulator host from env: $_envHost');
      return _envHost;
    }

    // 2. Web & Desktop always use localhost (or env host if provided above)
    if (kIsWeb || !Platform.isAndroid) {
      return _localhost;
    }

    // 3. Android: Check device type
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    // 3a. Genymotion detection
    if (_isGenymotion(androidInfo)) {
      log('🎮 Genymotion detected (${androidInfo.manufacturer}). Using host: $_genymotionHost');
      return _genymotionHost;
    }

    if (androidInfo.isPhysicalDevice) {
      // Physical Android Device
      // We CANNOT use localhost or 10.0.2.2.
      // If EMULATOR_HOST is not provided, return null so callers can skip
      // emulator configuration and avoid unnecessary timeouts.
      log('⚠️ PHYSICAL ANDROID DEVICE DETECTED ⚠️');
      log('   You must provide the developer machine IP to connect to emulators.');
      log('   Run with: flutter run --dart-define=EMULATOR_HOST=YOUR_LOCAL_IP');

      return null;
    }

    // Standard Android Emulator (AVD)
    return _androidEmulatorHost;
  }
}
