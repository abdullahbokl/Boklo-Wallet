import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/email_field.dart';
import 'package:boklo/features/auth/presentation/widgets/password_field.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegisterPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        getIt<SnackbarService>().showError('Passwords do not match');
        return;
      }
      await context.read<AuthCubit>().register(
            _emailController.text,
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
          EmailField(controller: _emailController),
          const SizedBox(height: AppSpacing.m),
          PasswordField(controller: _passwordController),
          const SizedBox(height: AppSpacing.m),
          PasswordField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
          ),
          const SizedBox(height: AppSpacing.l),
          BlocBuilder<AuthCubit, BaseState<User?>>(
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const Center(child: CircularProgressIndicator()),
                orElse: () => AppButton(
                  text: 'Register',
                  onPressed: _onRegisterPressed,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
