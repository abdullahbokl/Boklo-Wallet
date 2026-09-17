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
import 'package:boklo/shared/extensions/l10n.dart';
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
                  context.l10n.pleaseCompleteProfile,
                );
              } else {
                getIt<NavigationService>().go('/wallet');
                getIt<SnackbarService>().showSuccess(
                  context.l10n.welcomeBack(
                    user.displayName ?? context.l10n.username,
                  ),
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
                    LoginHeader(
                      title: context.l10n.signInToBoklo,
                      subtitle: context.l10n.signInSubtitle,
                    ),
                    const SizedBox(height: AppDimens.xl),
                    const AppCard(
                      padding: EdgeInsets.all(AppDimens.xl),
                      child: LoginForm(),
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
            context.l10n.newToBoklo,
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () => getIt<NavigationService>().push('/register'),
            child: Text(context.l10n.createAccount),
          ),
        ],
      ),
    );
  }
}
