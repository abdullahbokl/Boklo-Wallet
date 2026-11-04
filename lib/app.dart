import 'package:boklo/config/routes/app_router.dart';
import 'package:boklo/config/theme/app_theme.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:boklo/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();
    final snackbarService = getIt<SnackbarService>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => getIt<AuthCubit>()),
        BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => getIt<LocaleCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'Boklo',
                builder: (context, child) => MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 2,
                  child: child ?? const SizedBox.shrink(),
                ),
                scaffoldMessengerKey: snackbarService.scaffoldMessengerKey,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                // A null locale follows the system; 'ar' also switches the
                // global text direction to RTL automatically.
                locale: locale,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                routerConfig: appRouter.router,
              );
            },
          );
        },
      ),
    );
  }
}
