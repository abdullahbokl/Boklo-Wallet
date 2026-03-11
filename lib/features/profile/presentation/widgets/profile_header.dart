import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/shared/widgets/atoms/app_avatar.dart';
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

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.2),
                    scheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            AppAvatar(
              size: 100,
              name: user.displayName ?? user.username ?? user.email,
            ),
          ],
        ),
        const SizedBox(height: AppDimens.lg),
        Text(
          user.displayName ?? 'User',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '@${user.username}',
          style: AppTypography.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Text(
          user.email,
          style: AppTypography.caption.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
