import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/auth_background.dart';
import 'package:boklo/features/auth/presentation/widgets/login_header.dart';
import 'package:boklo/features/auth/presentation/widgets/profile_setup_form.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: BlocListener<AuthCubit, BaseState<User?>>(
          listener: (context, state) {
            state.whenOrNull(
              success: (user) {
                if (user != null && user.username != null) {
                  getIt<NavigationService>().go('/wallet');
                }
              },
              error: (error) => getIt<SnackbarService>().showError(error.message),
            );
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimens.maxFormWidth,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoginHeader(
                      title: 'Set up your profile',
                      subtitle:
                          'Choose a username others can use to find and pay you.',
                    ),
                    SizedBox(height: AppDimens.xl),
                    AppCard(
                      padding: EdgeInsets.all(AppDimens.xl),
                      child: ProfileSetupForm(),
                    ),
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
