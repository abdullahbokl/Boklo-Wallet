import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
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
      context.read<AuthCubit>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter your email' : null,
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _passwordController,
            hintText: 'Password',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter your password' : null,
            onSubmitted: (_) => _onLogin(),
          ),
          const SizedBox(height: AppSpacing.l),
          BlocBuilder<AuthCubit, BaseState<User?>>(
            builder: (context, state) {
              final isLoading = state.maybeWhen(
                loading: () => true,
                orElse: () => false,
              );
              return AppButton(
                text: 'Sign In',
                onPressed: isLoading ? null : _onLogin,
              );
            },
          ),
        ],
      ),
    );
  }
}
