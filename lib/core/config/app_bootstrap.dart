import 'dart:developer';

import 'package:boklo/app.dart';
import 'package:boklo/config/routes/app_router.dart';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

class AppBootstrap {
  static Future<void> bootstrap({
    required String environment,
    required FirebaseOptions firebaseOptions,
    bool useFirebaseEmulator = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: firebaseOptions);

    await _configureAppCheck(
      useEmulator: useFirebaseEmulator,
      environment: environment,
    );
    await _configureEmulators(useFirebaseEmulator);
    await configureDependencies(environment);

    await getIt<AuthCubit>().checkAuthStatus();
    await _initializeServices();
    await _setupInitialRoute();

    runApp(const MyApp());
  }

  static Future<void> _configureAppCheck({
    required bool useEmulator,
    required String environment,
  }) async {
    if (useEmulator) {
      log('⏭️ App Check skipped (Emulator mode)');
      return;
    }

    // In prod flavor, always use real attestation providers
    // even on debug builds.
    // This prevents production backends from rejecting debug-provider tokens.
    final isProdFlavor = environment == Environment.prod;
    final useDebugProviders = !isProdFlavor && kDebugMode;

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: useDebugProviders
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: useDebugProviders
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );
      log(
        '✅ App Check activation call completed '
        '(env=$environment, debugProviders=$useDebugProviders)',
      );
    } on Object catch (e) {
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
    } on Object catch (e) {
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
