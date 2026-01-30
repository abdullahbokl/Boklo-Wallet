import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class EmulatorConfig {
  static const int _authPort = 9099;
  static const int _firestorePort = 8080;
  static const int _functionsPort = 5001;
  static const int _storagePort = 9199;

  static const String _androidEmulatorHost = '10.0.2.2';
  static const String _localhost = 'localhost';

  // Allow passing host via command line: --dart-define=EMULATOR_HOST=192.168.1.X
  static const String _envHost = String.fromEnvironment('EMULATOR_HOST');

  static String? _resolvedHost;
  static String? get resolvedHost => _resolvedHost;

  static Future<void> configure() async {
    final host = await _resolveHost();
    _resolvedHost = host;

    bool isPhysicalAndroid = false;
    if (!kIsWeb && Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      isPhysicalAndroid = androidInfo.isPhysicalDevice;
    }

    log('🔥 Configuring Firebase Emulators at $host');

    // 1. Auth (Hybrid: Real Auth on Physical, Emulator on others)
    if (isPhysicalAndroid) {
      log('⚠️ Hybrid Setup: Using REAL Firebase Auth on Physical Device');
      // Do NOT enable Auth emulator
    } else {
      FirebaseAuth.instance.useAuthEmulator(host, _authPort);
      FirebaseAuth.instance.setLanguageCode('en');
    }

    // 2. Firestore
    FirebaseFirestore.instance.useFirestoreEmulator(host, _firestorePort);

    // 3. Functions (use explicit region to match app_module.dart)
    FirebaseFunctions.instanceFor(region: 'us-central1')
        .useFunctionsEmulator(host, _functionsPort);

    // 4. Storage
    FirebaseStorage.instance.useStorageEmulator(host, _storagePort);

    // 5. Force Token Reload
    // Ensures auth state is consistent (clears stale emulator tokens if switching to real auth)
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

  static Future<String> _resolveHost() async {
    // 1. If host is explicitly provided via env (e.g. for physical device testing), use it.
    if (_envHost.isNotEmpty) {
      log('🔥 Using explicit emulator host from env: $_envHost');
      return _envHost;
    }

    // 2. Web & Desktop always use localhost (or env host if provided above)
    if (kIsWeb || !Platform.isAndroid) {
      return _localhost;
    }

    // 3. Android: Check if Emulator or Physical
    // We use device_info_plus to distinguish.
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.isPhysicalDevice) {
      // Physical Android Device
      // We CANNOT use localhost or 10.0.2.2.
      // We MUST fail or warn if EMULATOR_HOST is not provided.
      log('⚠️ PHYSICAL ANDROID DEVICE DETECTED ⚠️');
      log('   You must provide the developer machine IP to connect to emulators.');
      log('   Run with: flutter run --dart-define=EMULATOR_HOST=YOUR_LOCAL_IP');

      // Fallback to a throw or a useless localhost to fail fast?
      // Returning localhost on physical device will effectively fail connection (ECONNREFUSED)
      // which is better than connecting to wrong 10.0.2.2 (timeout)
      return _localhost; // This will fail, but with a clear log above.
    } else {
      // Android Emulator
      return _androidEmulatorHost;
    }
  }
}
