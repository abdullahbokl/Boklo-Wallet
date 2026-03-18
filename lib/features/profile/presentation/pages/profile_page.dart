import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/profile/presentation/widgets/account_details_card.dart';
import 'package:boklo/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:boklo/features/profile/presentation/widgets/profile_header.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
        title: 'Profile',
        child: BlocBuilder<AuthCubit, BaseState<User?>>(
          builder: (context, state) {
            return state.when(
              initial: () => const AppLoadingIndicator(),
              loading: () => const AppLoadingIndicator(),
              error: (failure) => WalletErrorView(
                title: failure.message,
                onRetry: () => context.read<AuthCubit>().checkAuthStatus(),
              ),
              success: (user) {
                if (user == null) {
                  return const Center(
                    child: Text('Please sign in to view profile.'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(
                    top: AppDimens.md,
                    bottom: AppDimens.xxl,
                  ),
                  children: [
                    ProfileHeader(user: user),
                    const SizedBox(height: AppDimens.xl),
                    const AccountDetailsCard(),
                    const SizedBox(height: AppDimens.xl),
                    AppButton(
                      text: 'Sign out',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _handleLogout(context),
                    ),
                    const SizedBox(height: AppDimens.md),
                    AppButton(
                      text: 'Delete account',
                      variant: AppButtonVariant.destructive,
                      onPressed: () => _showDeleteAccountDialog(context),
                    ),
                    const SizedBox(height: AppDimens.md),
                    Center(
                      child: Text(
                        'v1.0.0 beta',
                        style: AppTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthCubit>().logout();

    if (!context.mounted) {
      return;
    }

    final state = context.read<AuthCubit>().state;
    if (state.data == null && !state.isError) {
      getIt<NavigationService>().go('/login');
    } else if (state.error != null) {
      getIt<SnackbarService>().showError(state.error!.message);
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (!context.mounted || password == null) {
      return;
    }

    await context.read<AuthCubit>().deleteAccount(password);

    if (!context.mounted) {
      return;
    }

    final state = context.read<AuthCubit>().state;
    if (state.data == null && !state.isError) {
      getIt<NavigationService>().go('/login');
      getIt<SnackbarService>().showSuccess(
        'Your account has been deleted successfully.',
      );
    } else if (state.error != null) {
      getIt<SnackbarService>().showError(state.error!.message);
      await context.read<AuthCubit>().checkAuthStatus();
    }
  }
}
