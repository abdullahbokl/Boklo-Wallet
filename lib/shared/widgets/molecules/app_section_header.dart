import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// A section header with a title and optional trailing widget.
///
/// Used to visually separate sections in scrollable pages
/// (e.g., "Recent Transactions" with a "See All" button).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    super.key,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: AppDimens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.title.copyWith(color: scheme.onSurface),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
