import 'dart:developer';
import 'dart:io';

import 'package:boklo/config/routes/app_router.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    if (useFirebaseEmulator) {
      await _configureEmulators();
    }

    await configureDependencies(environment);

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

  static Future<void> _configureEmulators() async {
    const authPort = 9099;
    const firestorePort = 8080;

    final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

    log('🔥 Using Firebase Emulators at $host');

    await FirebaseAuth.instance.useAuthEmulator(host, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(host, firestorePort);
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: appRouter.router,
      ),
    );
  }
}
