import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge:
            AppTypography.display.copyWith(color: AppColors.textPrimaryLight),
        headlineLarge:
            AppTypography.headline.copyWith(color: AppColors.textPrimaryLight),
        titleLarge:
            AppTypography.title.copyWith(color: AppColors.textPrimaryLight),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.textPrimaryLight),
        bodyMedium: AppTypography.bodyMedium
            .copyWith(color: AppColors.textPrimaryLight),
        labelLarge: AppTypography.label.copyWith(color: AppColors.primary),
        bodySmall:
            AppTypography.caption.copyWith(color: AppColors.textSecondaryLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          textStyle: AppTypography.label.copyWith(fontSize: 16),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.md,
            horizontal: AppDimens.lg,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppDimens.md,
          horizontal: AppDimens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide:
              BorderSide(color: AppColors.textSecondaryLight.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide:
              BorderSide(color: AppColors.textSecondaryLight.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTypography.bodyMedium
            .copyWith(color: AppColors.textSecondaryLight),
        labelStyle: AppTypography.bodyMedium
            .copyWith(color: AppColors.textSecondaryLight),
      ),
    );
  }

  // Define darkTheme similarly if needed, or stick to light for MVP premium feel first.
}
