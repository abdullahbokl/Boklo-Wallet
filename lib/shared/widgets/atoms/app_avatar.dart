import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Displays a user avatar with photo or gradient initials fallback.
///
/// Sizes: [AppDimens.avatarSm], [AppDimens.avatarMd], [AppDimens.avatarLg].
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.size = AppDimens.avatarMd,
    this.showBorder = false,
  });

  final String? photoUrl;
  final String? name;
  final double size;
  final bool showBorder;

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final borderDecoration = showBorder
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          )
        : null;

    return Container(
      width: size,
      height: size,
      decoration: borderDecoration,
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage:
            photoUrl != null ? NetworkImage(photoUrl!) : null,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: photoUrl == null
            ? Text(
                _initials,
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontSize: size * 0.35,
                ),
              )
            : null,
      ),
    );
  }
}
