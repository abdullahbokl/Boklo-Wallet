import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/shared/widgets/atoms/app_avatar.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    super.key,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Column(
        children: [
          AppAvatar(
            size: AppDimens.avatarXl,
            name: user.displayName ?? user.username ?? user.email,
            showBorder: true,
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
            user.displayName ?? 'Boklo user',
            style: AppTypography.headline.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppDimens.xs4),
          Text(
            '@${user.username ?? 'pending'}',
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            user.email,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
