import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.size = AppDimens.avatarMd,
    this.showBorder = false,
    this.onTap,
  });

  final String? photoUrl;
  final String? name;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  String get _initials {
    if (name == null || name!.isEmpty) {
      return '?';
    }

    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
                width: 2,
              )
            : null,
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.transparent,
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
        child: photoUrl == null
            ? Text(
                _initials,
                style: AppTypography.label.copyWith(
                  color: scheme.primary,
                  fontSize: size * 0.32,
                ),
              )
            : null,
      ),
    );

    if (onTap == null) {
      return avatar;
    }

    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }
}
