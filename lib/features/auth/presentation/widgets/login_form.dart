import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/email_field.dart';
import 'package:boklo/features/auth/presentation/widgets/password_field.dart';
import 'package:boklo/config/theme/app_dimens.dart'; // UPDATED
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      unawaited(
        context.read<AuthCubit>().login(
              _emailController.text.trim(),
              _passwordController.text,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: BlocBuilder<AuthCubit, BaseState<User?>>(
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailField(
                controller: _emailController,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimens.md), // UPDATED SPACING
              PasswordField(
                controller: _passwordController,
                onSubmitted: isLoading ? null : (_) => _onLogin(),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimens.xl), // UPDATED SPACING
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Sign In',
                      onPressed: _onLogin,
                      isLoading: isLoading,
                      // New AppButton defaults to premium styling automatically
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  AppButton(
                    text: "Don't have an account? Sign up",
                    isSecondary: true, // Use secondary style for link
                    onPressed: isLoading
                        ? null
                        : () =>
                            getIt<NavigationService>().push<void>('/register'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
