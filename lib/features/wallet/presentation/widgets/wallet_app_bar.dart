import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/shared/widgets/atoms/app_avatar.dart';
import 'package:boklo/shared/widgets/atoms/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WalletAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimens.md),
        child: BlocBuilder<AuthCubit, BaseState<User?>>(
          builder: (context, authState) {
            final user = authState.maybeWhen(
              success: (user) => user,
              orElse: () => null,
            );
            return AppAvatar(
              size: 40,
              name: user?.displayName ?? user?.email,
              onTap: () => getIt<NavigationService>().push('/profile'),
            );
          },
        ),
      ),
      leadingWidth: 40 + AppDimens.md,
      title: BlocBuilder<WalletCubit, BaseState<WalletState>>(
        builder: (context, walletState) {
          final name = walletState.maybeWhen(
            success: (data) => data.wallet.ownerName,
            orElse: () => null,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Good morning',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                name != null && name.isNotEmpty ? name : 'User',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          );
        },
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [
        AppIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => getIt<NavigationService>().push('/notifications'),
        ),
        const SizedBox(width: AppDimens.xs),
        AppIconButton(
          icon: Icons.settings_outlined,
          onTap: () => getIt<NavigationService>().push('/notification-settings'),
        ),
        const SizedBox(width: AppDimens.md),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
