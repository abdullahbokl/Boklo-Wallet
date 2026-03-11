import 'package:boklo/app.dart';
import 'package:boklo/config/routes/app_router.dart';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'dart:developer';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppBootstrap {
  static Future<void> bootstrap({
    required String environment,
    required FirebaseOptions firebaseOptions,
    bool useFirebaseEmulator = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: firebaseOptions);

    await _configureAppCheck(useFirebaseEmulator);
    await _configureEmulators(useFirebaseEmulator);
    await configureDependencies(environment);

    await getIt<AuthCubit>().checkAuthStatus();
    await _initializeServices();
    await _setupInitialRoute();

    runApp(const MyApp());
  }

  static Future<void> _configureAppCheck(bool useEmulator) async {
    if (useEmulator) {
      log('⏭️ App Check skipped (Emulator mode)');
      return;
    }
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
      log('✅ App Check activation call completed');
    } catch (e) {
      log('⚠️ App Check activation failed: $e');
    }
  }

  static Future<void> _configureEmulators(bool useEmulator) async {
    if (useEmulator) {
      log('🔧 Configuring Firebase Emulators...');
      await EmulatorConfig.configure();
      log('✅ Emulator configuration complete');
    }
  }

  static Future<void> _initializeServices() async {
    try {
      await getIt<NotificationService>().initialize();
    } catch (e) {
      log('Failed to initialize notifications: $e');
    }
  }

  static Future<void> _setupInitialRoute() async {
    final authRepository = getIt<AuthRepository>();
    final userResult = await authRepository.getCurrentUser();

    var initialRoute = '/login';
    userResult.fold(
      (_) => null,
      (user) {
        if (user != null) initialRoute = '/wallet';
      },
    );

    getIt<AppRouter>().initialLocation = initialRoute;
  }
}
