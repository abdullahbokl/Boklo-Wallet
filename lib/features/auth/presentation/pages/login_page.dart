import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/auth_background.dart';
import 'package:boklo/features/auth/presentation/widgets/login_form.dart';
import 'package:boklo/features/auth/presentation/widgets/login_header.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, BaseState<User?>>(
      listener: (context, state) {
        state.whenOrNull(
          error: (error) {
            getIt<SnackbarService>().showError(error.message);
          },
          success: (user) {
            if (user != null) {
              if (user.username == null) {
                getIt<NavigationService>().go('/profile-setup');
                getIt<SnackbarService>()
                    .showSuccess('Please set up your profile');
              } else {
                getIt<NavigationService>().go('/wallet');
                getIt<SnackbarService>().showSuccess(
                  'Welcome ${user.displayName ?? "User"}',
                );
              }
            }
          },
        );
      },
      child: Scaffold(
        body: AuthBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoginHeader(
                    title: 'Welcome Back!',
                    subtitle: 'Sign in to continue to Boklo Wallet',
                  ),
                  const SizedBox(height: AppDimens.xxl),
                  AppCard(
                    useGlass: true,
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: const LoginForm(),
                  ),
                  const SizedBox(height: AppDimens.xl),
                  const _LoginFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account? ',
          style: AppTypography.bodyMedium.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        TextButton(
          onPressed: () => getIt<NavigationService>().push('/register'),
          child: Text(
            'Register Now',
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
