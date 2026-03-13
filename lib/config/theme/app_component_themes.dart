import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppComponentThemes {
  AppComponentThemes._();

  // 1. CACHE CONSTANT SHAPES
  // Moving these to static const variables prevents Flutter from re-allocating
  // memory for borders and radii every time the theme is built.
  static const _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusLg)),
  );

  static const _chipShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusFull)),
  );

  static const _listTileShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusLg)),
  );

  static const _inputRadius = BorderRadius.all(Radius.circular(AppDimens.radiusMd));

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
      // 2. USE CACHED HELPER
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
      shape: _cardShape, // Reused cached shape
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
      shape: _chipShape, // Reused cached shape
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
      shape: _listTileShape, // Reused cached shape
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

  // 3. OPTIMIZED BORDER HELPER
  // Uses the cached _inputRadius instead of generating a new BorderRadius
  // on every single OutlineInputBorder creation.
  static OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: _inputRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}