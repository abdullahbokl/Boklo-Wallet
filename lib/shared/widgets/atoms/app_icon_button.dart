import 'package:boklo/config/theme/app_dimens.dart';
import 'package:flutter/material.dart';

/// A circular icon button with a tinted background.
///
/// Used in app bars, quick-action grids, and dialogs
/// for consistent icon-button styling.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onTap,
    super.key,
    this.color,
    this.size = AppDimens.iconMd,
    this.backgroundColor,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final double size;
  final Color? backgroundColor;
  final String? tooltip;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.onSurface;
    final bgColor =
        backgroundColor ?? effectiveColor.withValues(alpha: 0.08);

    Widget button = Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xs),
          child: Icon(icon, size: size, color: effectiveColor),
        ),
      ),
    );

    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [button, Positioned(right: -2, top: -2, child: badge!)],
      );
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
