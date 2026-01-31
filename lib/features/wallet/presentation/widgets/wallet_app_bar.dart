import 'dart:async';

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WalletAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: BlocBuilder<WalletCubit, BaseState<WalletState>>(
        builder: (context, walletState) {
          final name = walletState.maybeWhen(
            success: (data) => data.wallet.ownerName,
            orElse: () => null,
          );
          return Text(
            name != null && name.isNotEmpty ? 'Hi 👋, $name!' : 'Hi 👋',
            style: AppTypography.headline.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          );
        },
      ),
      centerTitle: false,
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      actions: const [_LogoutButton()],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
      child: BlocBuilder<AuthCubit, BaseState<User?>>(
        builder: (context, authState) {
          final isLoggingOut = authState.isLoading;
          return InkWell(
            onTap: isLoggingOut
                ? null
                : () {
                    unawaited(context.read<AuthCubit>().logout());
                  },
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.md,
                vertical: AppDimens.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoggingOut)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isLoggingOut ? 'Logging out...' : 'Logout',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
