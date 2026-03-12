import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:flutter/material.dart';

class AppDecorations {
  AppDecorations._();

  static BoxDecoration glassCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.glassDark : AppColors.glassLight,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(
        color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
      ),
      boxShadow: AppColors.shadowMd,
    );
  }

  static BoxDecoration gradientCard() {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      boxShadow: AppColors.shadowLg,
    );
  }

  static BoxDecoration surfaceCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(color: scheme.outlineVariant),
      boxShadow: AppColors.shadowSm,
    );
  }

  static BoxDecoration mainGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                AppColors.pageTintDark,
                scheme.surface,
                scheme.surface,
              ]
            : [
                AppColors.pageTintLight,
                scheme.surface,
                scheme.surface,
              ],
        stops: const [0, 0.34, 1],
      ),
    );
  }

  static BoxDecoration mutedPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      border: Border.all(color: scheme.outlineVariant),
    );
  }
}
