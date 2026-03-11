import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/email_field.dart';
import 'package:boklo/features/auth/presentation/widgets/password_field.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';

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
    final scheme = Theme.of(context).colorScheme;

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
              const SizedBox(height: AppDimens.md),
              PasswordField(
                controller: _passwordController,
                onSubmitted: isLoading ? null : (_) => _onLogin(),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimens.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading ? null : () {}, // Forgot password placeholder
                  child: Text(
                    'Forgot Password?',
                    style: AppTypography.label.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.lg),
              AppButton(
                text: 'Sign In',
                onPressed: _onLogin,
                isLoading: isLoading,
                width: double.infinity,
              ),
            ],
          );
        },
      ),
    );
  }
}
