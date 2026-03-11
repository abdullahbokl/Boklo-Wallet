import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/profile/presentation/widgets/account_details_card.dart';
import 'package:boklo/features/profile/presentation/widgets/profile_header.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: scheme.onSurface),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: 0.15),
              scheme.surface,
              scheme.surface,
            ],
          ),
        ),
        child: BlocBuilder<AuthCubit, BaseState<User?>>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (failure) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: AppDimens.md),
                    Text(failure.message),
                    const SizedBox(height: AppDimens.md),
                    AppButton(
                      text: 'Retry',
                      onPressed: () => context.read<AuthCubit>().checkAuthStatus(),
                    ),
                  ],
                ),
              ),
              success: (user) {
                if (user == null) {
                  return const Center(child: Text('Please login to view profile'));
                }
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Column(
                      children: [
                        ProfileHeader(user: user),
                        const SizedBox(height: AppDimens.xl * 1.5),
                        const AccountDetailsCard(),
                        const SizedBox(height: AppDimens.xl * 2),
                        AppButton(
                          text: 'Sign Out',
                          isSecondary: true,
                          onPressed: () => context.read<AuthCubit>().logout(),
                        ),
                        const SizedBox(height: AppDimens.xl),
                        Text(
                          'v1.0.0 (BETA)',
                          style: AppTypography.caption.copyWith(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
