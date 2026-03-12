import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/auth_background.dart';
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
          error: (error) => getIt<SnackbarService>().showError(error.message),
          success: (user) {
            if (user != null) {
              getIt<NavigationService>().go('/profile-setup');
              getIt<SnackbarService>().showSuccess(
                'Account created. Finish setting up your profile.',
              );
            }
          },
        );
      },
      child: Scaffold(
        body: AuthBackground(
          stackChildren: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: AppDimens.xs),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => getIt<NavigationService>().pop(),
                ),
              ),
            ),
          ],
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
                      title: 'Create your Boklo account',
                      subtitle:
                          'Open a secure wallet and start sending or requesting money.',
                    ),
                    const SizedBox(height: AppDimens.xl),
                    AppCard(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: const RegisterForm(),
                    ),
                    const SizedBox(height: AppDimens.lg),
                    const _RegisterFooter(),
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

class _RegisterFooter extends StatelessWidget {
  const _RegisterFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () => getIt<NavigationService>().pop(),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
