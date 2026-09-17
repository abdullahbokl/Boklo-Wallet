import 'dart:developer';

import 'package:boklo/app.dart';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AppBootstrap {
  static Future<void> bootstrap({
    required String environment,
    required FirebaseOptions firebaseOptions,
    bool useFirebaseEmulator = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: firebaseOptions);
    log(
      '🔥 Firebase project: ${Firebase.app().options.projectId} '
      '(env=$environment)',
    );

    await _configureAppCheck(isDev: environment == 'dev');

    await _configureEmulators(useEmulator: useFirebaseEmulator);
    await configureDependencies(environment);

    // Resolve the persisted auth session BEFORE the first frame so the
    // router's redirect guard immediately lands on the correct screen.
    await getIt<AuthCubit>().checkAuthStatus();

    await _initializeServices();

    runApp(const MyApp());
  }

  /// App Check attestation: Play Integrity (Android) / App Attest (iOS) in
  /// production, debug provider in development. Enforcement for Firestore,
  /// Storage, and Functions is toggled in the Firebase console.
  static Future<void> _configureAppCheck({required bool isDev}) async {
    try {
      final appCheck = FirebaseAppCheck.instance;
      if (isDev) {
        await appCheck.activate(
          providerAndroid: const AndroidDebugProvider(),
          providerApple: const AppleDebugProvider(),
        );
      } else {
        // Defaults: Play Integrity (Android) / App Attest (Apple).
        await appCheck.activate();
      }
      log('🛡️ App Check activated (${isDev ? 'debug' : 'integrity'})');
    } on Object catch (e) {
      log('App Check activation failed: $e');
    }
  }

  static Future<void> _configureEmulators({required bool useEmulator}) async {
    if (useEmulator) {
      log('🔧 Configuring Firebase Emulators...');
      await EmulatorConfig.configure();
      log('✅ Emulator configuration complete');
    }
  }

  static Future<void> _initializeServices() async {
    try {
      await getIt<NotificationService>().initialize();
    } on Object catch (e) {
      log('Failed to initialize notifications: $e');
    }
  }
}
