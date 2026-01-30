import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/login_header.dart';
import 'package:boklo/features/auth/presentation/widgets/register_form.dart';
import 'package:boklo/shared/responsive/responsive_builder.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
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
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                getIt<NavigationService>().pushReplacement('/login'),
          ),
        ),
        body: ResponsiveBuilder(
          mobile: (context, _) => const _RegisterLayout(),
          tablet: (context, _) => const Center(
            child: SizedBox(width: 500, child: _RegisterLayout()),
          ),
          desktop: (context, _) => const Center(
            child: SizedBox(width: 400, child: _RegisterLayout()),
          ),
        ),
      ),
    );
  }
}

class _RegisterLayout extends StatelessWidget {
  const _RegisterLayout();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginHeader(
            title: 'Create Account',
            subtitle: 'Sign up to get started',
          ),
          SizedBox(height: AppSpacing.xxl),
          RegisterForm(),
        ],
      ),
    );
  }
}
