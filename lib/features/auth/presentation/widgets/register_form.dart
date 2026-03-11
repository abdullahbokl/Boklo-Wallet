import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/email_field.dart';
import 'package:boklo/features/auth/presentation/widgets/password_field.dart';
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
      child: BlocSelector<AuthCubit, BaseState<User?>, bool>(
        selector: (state) {
          return state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
        },
        builder: (context, isLoading) {
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
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimens.md),
              PasswordField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimens.xl),
              AppButton(
                text: 'Create Account',
                onPressed: _onRegisterPressed,
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
