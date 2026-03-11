import 'package:flutter/material.dart';
import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';

/// Reusable decoration presets for cards, containers, and sections.
class AppDecorations {
  AppDecorations._();

  /// Frosted-glass card decoration — adapts to light/dark.
  static BoxDecoration glassCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.glassDark : AppColors.glassLight,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(
        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
      ),
      boxShadow: AppColors.shadowSm,
    );
  }

  /// Primary gradient card with large radius and shadow.
  static BoxDecoration gradientCard() {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      boxShadow: AppColors.shadowLg,
    );
  }

  /// Themed surface card — solid surface color with subtle border.
  static BoxDecoration surfaceCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
      boxShadow: AppColors.shadowSm,
    );
  }
}
