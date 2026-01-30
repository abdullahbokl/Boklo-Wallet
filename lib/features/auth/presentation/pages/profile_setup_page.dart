import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();

  // Allowed chars: a-z 0-9 _ .
  final _usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().setUserProfile(
            username: _usernameController.text.trim(),
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent going back without profile
      ),
      body: BlocListener<AuthCubit, BaseState<User?>>(
        listener: (context, state) {
          state.whenOrNull(
            success: (user) {
              if (user != null && user.username != null) {
                // Profile set! Go to home.
                getIt<NavigationService>().go('/wallet');
              }
            },
            error: (error) {
              getIt<SnackbarService>().showError(error.message);
            },
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose a unique username',
                  style: AppTypography.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.sm),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'This will be your identity for sending and receiving money.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.xl),
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hintText: 'boklo_user',
                  prefixIcon: const Icon(Icons.alternate_email),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(_usernameRegex),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!_usernameRegex.hasMatch(value)) {
                      return 'Only letters, numbers, dots, and underscores allowed';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.md),
                AppTextField(
                  controller: _nameController,
                  label: 'Display Name (Optional)',
                  hintText: 'John Doe',
                  prefixIcon: const Icon(Icons.person_outline),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                ),
                const SizedBox(height: AppDimens.xl),
                BlocBuilder<AuthCubit, BaseState<User?>>(
                  builder: (context, state) {
                    final isLoading = state.maybeWhen(
                      loading: () => true,
                      orElse: () => false,
                    );

                    return AppButton(
                      text: 'Continue',
                      isLoading: isLoading,
                      onPressed: _submit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
