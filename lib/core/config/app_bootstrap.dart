import 'dart:developer';

import 'package:boklo/app.dart';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
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

    await _configureEmulators(useEmulator: useFirebaseEmulator);
    await configureDependencies(environment);

    // Resolve the persisted auth session BEFORE the first frame so the
    // router's redirect guard immediately lands on the correct screen.
    await getIt<AuthCubit>().checkAuthStatus();

    await _initializeServices();

    runApp(const MyApp());
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
