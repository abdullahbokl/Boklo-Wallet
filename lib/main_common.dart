import 'package:boklo/core/config/app_config.dart';
import 'package:boklo/core/di/dependency_injection.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register AppConfig before other dependencies
  // We can't use @LazySingleton for AppConfig because it's dynamic
  // So we register it manually
  configureDependencies();
  getIt.registerSingleton<AppConfig>(config);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthBloc>()),
      ],
      child: MaterialApp(
        title: 'Boklo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: Text('Boklo FinTech App Initialized'),
          ),
        ),
      ),
    );
  }
}
