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
          error: (error) => getIt<SnackbarService>().showError(error.message),
          success: (user) {
            if (user != null) {
              if (user.username == null) {
                getIt<NavigationService>().go('/profile-setup');
                getIt<SnackbarService>().showSuccess(
                  'Please complete your profile setup.',
                );
              } else {
                getIt<NavigationService>().go('/wallet');
                getIt<SnackbarService>().showSuccess(
                  'Welcome back, ${user.displayName ?? 'User'}.',
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
              padding: const EdgeInsets.symmetric(vertical: AppDimens.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimens.maxFormWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LoginHeader(
                      title: 'Sign in to Boklo',
                      subtitle:
                          'Secure access to your wallet, transfers, and requests.',
                    ),
                    const SizedBox(height: AppDimens.xl),
                    AppCard(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: const LoginForm(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    const _LoginFooter(),
                  ],
                ),
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
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'New to Boklo? ',
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () => getIt<NavigationService>().push('/register'),
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
