import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppComponentThemes {
  AppComponentThemes._();

  static InputDecorationTheme input(
    bool isDark,
    Color hintColor,
    Color fillColor,
  ) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppDimens.md,
        horizontal: AppDimens.md,
      ),
      border: _outlineBorder(borderColor),
      enabledBorder: _outlineBorder(borderColor),
      focusedBorder: _outlineBorder(primary, width: 1.5),
      errorBorder: _outlineBorder(AppColors.error),
      focusedErrorBorder: _outlineBorder(AppColors.error, width: 1.5),
      hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
      labelStyle: AppTypography.bodySmall.copyWith(color: hintColor),
    );
  }

  static CardThemeData card(Color surface) {
    return CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
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
      selectedColor: primary.withValues(alpha: 0.12),
      labelStyle: AppTypography.label.copyWith(color: textColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      side: BorderSide(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs4,
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
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
    );
  }

  static TabBarThemeData tabBar(Color selected, Color unselected) {
    return TabBarThemeData(
      labelColor: selected,
      unselectedLabelColor: unselected,
      indicatorColor: selected,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTypography.label,
      unselectedLabelStyle: AppTypography.bodyMedium,
      dividerColor: Colors.transparent,
    );
  }

  static OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
