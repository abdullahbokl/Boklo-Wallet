import 'package:boklo/config/routes/app_router.dart';
import 'package:boklo/core/config/app_config.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBootstrap {
  static Future<void> bootstrap({
    required AppConfig config,
    required FirebaseOptions firebaseOptions,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: firebaseOptions,
    );

    // Register AppConfig before other dependencies
    getIt.registerSingleton<AppConfig>(config);
    await configureDependencies();

    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Boklo',
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
