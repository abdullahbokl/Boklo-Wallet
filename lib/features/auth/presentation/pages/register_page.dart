import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/login_header.dart';
import 'package:boklo/features/auth/presentation/widgets/register_form.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

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
                getIt<SnackbarService>().showSuccess(
                  'Registration successful! Please set up your profile.',
                );
              } else {
                getIt<NavigationService>().go('/wallet');
                getIt<SnackbarService>().showSuccess(
                  'Registration successful! Welcome.',
                );
              }
            }
          },
        );
      },
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;

          return Scaffold(
            body: Stack(
              children: [
                // Background Gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.1),
                        scheme.primaryContainer.withValues(alpha: 0.05),
                        scheme.surface,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Back Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimens.sm,
                      top: AppDimens.sm,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => getIt<NavigationService>().pop(),
                      color: scheme.onSurface,
                    ),
                  ),
                ),

                // Main Content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimens.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const LoginHeader(
                            title: 'Create Account',
                            subtitle: 'Join Boklo Wallet today',
                          ),
                          const SizedBox(height: AppDimens.xxl),
                          AppCard(
                            useGlass: true,
                            padding: const EdgeInsets.all(AppDimens.lg),
                            child: const RegisterForm(),
                          ),
                          const SizedBox(height: AppDimens.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              TextButton(
                                onPressed: () => getIt<NavigationService>().pop(),
                                child: Text(
                                  'Login',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
