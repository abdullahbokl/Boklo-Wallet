import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/presentation/widgets/profile_setup_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileSetupPage extends StatelessWidget {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
          child: const ProfileSetupForm(),
        ),
      ),
    );
  }
}
