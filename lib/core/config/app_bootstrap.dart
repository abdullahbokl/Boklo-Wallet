import 'package:boklo/config/routes/app_router.dart';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'dart:developer';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boklo/config/theme/app_theme.dart'; // NEW
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class AppBootstrap {
  static Future<void> bootstrap({
    required String environment,
    required FirebaseOptions firebaseOptions,
    bool useFirebaseEmulator = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: firebaseOptions,
    );

    // Task A: Ensure App Check is configured before any Firestore/Functions call
    try {
      // NOTE: If using physical device + emulator, ensure you have set the
      // debug token in Firebase Console if using AndroidProvider.debug.
      // 403 errors indicate the App Check API is disabled in the Google Cloud Console.
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
      log('✅ App Check activation call completed');
    } on Exception catch (e) {
      log('⚠️ App Check activation failed (Expected in some DEV setups): $e');
    }

    if (useFirebaseEmulator) {
      log('🔧 Configuring Firebase Emulators...');
      await EmulatorConfig.configure();
      log('✅ Emulator configuration complete. Host: ${EmulatorConfig.resolvedHost}');
    } else {
      log('🌐 Running in PRODUCTION mode (no emulators)');
    }

    await configureDependencies(environment);

    // Initialize Notifications
    try {
      await getIt<NotificationService>().initialize();
    } catch (e) {
      log('Failed to initialize notifications: $e');
    }

    final authRepository = getIt<AuthRepository>();
    final userResult = await authRepository.getCurrentUser();

    // Default to login
    var initialRoute = '/login';

    // Check if user is authenticated
    userResult.fold(
      (error) {
        // Stay on login
      },
      (user) {
        if (user != null) {
          initialRoute = '/wallet';
        }
      },
    );

    // Set initial location in AppRouter before MyApp accesses it
    getIt<AppRouter>().initialLocation = initialRoute;

    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();
    final snackbarService = getIt<SnackbarService>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Boklo',
        scaffoldMessengerKey: snackbarService.scaffoldMessengerKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme, // Use the new theme
        routerConfig: appRouter.router,
      ),
    );
  }
}
