import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:flutter/material.dart';

/// A themed card with glassmorphic or surface styling.
///
/// Uses [AppDecorations.glassCard] by default.
/// Set [useGlass] to false for a solid surface card.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.useGlass = true,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final bool useGlass;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = useGlass
        ? AppDecorations.glassCard(context)
        : AppDecorations.surfaceCard(context);

    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppDimens.md),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
