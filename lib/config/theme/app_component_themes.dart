import 'package:flutter/material.dart';
import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';

/// Component-level theme configurations extracted from [AppTheme]
/// to keep each file ≤ 120 lines.
class AppComponentThemes {
  AppComponentThemes._();

  static InputDecorationTheme input(
    bool isDark,
    Color hintColor,
    Color fillColor,
  ) {
    final borderColor = isDark
        ? AppColors.textSecondaryDark.withValues(alpha: 0.3)
        : AppColors.textSecondaryLight.withValues(alpha: 0.2);
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppDimens.md,
        horizontal: AppDimens.md,
      ),
      border: _outlineBorder(borderColor),
      enabledBorder: _outlineBorder(borderColor),
      focusedBorder: _outlineBorder(primary, width: 2),
      errorBorder: _outlineBorder(AppColors.error),
      hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
      labelStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
    );
  }

  static CardThemeData card(Color surface) {
    return CardThemeData(
      color: surface,
      elevation: AppDimens.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: AppDimens.xs,
        horizontal: AppDimens.md,
      ),
    );
  }

  static ChipThemeData chip(
    bool isDark,
    Color textColor,
    Color surface,
    Color primary,
  ) {
    return ChipThemeData(
      backgroundColor: surface,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: AppTypography.label.copyWith(color: textColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      side: BorderSide(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
    );
  }

  static ListTileThemeData listTile(Color textColor) {
    return ListTileThemeData(
      textColor: textColor,
      iconColor: textColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
    );
  }

  static TabBarThemeData tabBar(Color selected, Color unselected) {
    return TabBarThemeData(
      labelColor: selected,
      unselectedLabelColor: unselected,
      indicatorColor: selected,
      labelStyle: AppTypography.label,
      unselectedLabelStyle: AppTypography.bodyMedium,
    );
  }

  // ── Helpers ──

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
