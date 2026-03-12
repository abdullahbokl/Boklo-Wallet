import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_component_themes.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme : _lightScheme;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final divider = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      dividerColor: divider,
      textTheme: _textTheme(textPrimary, textSecondary, primary),
      appBarTheme: _appBarTheme(textPrimary),
      elevatedButtonTheme: _elevatedButtonTheme(primary),
      inputDecorationTheme:
          AppComponentThemes.input(isDark, textSecondary, surface),
      cardTheme: AppComponentThemes.card(surface),
      chipTheme: AppComponentThemes.chip(isDark, textPrimary, surface, primary),
      listTileTheme: AppComponentThemes.listTile(textPrimary),
      tabBarTheme: AppComponentThemes.tabBar(primary, textSecondary),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
      ),
    );
  }

  static const _lightScheme = ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceLight,
    surfaceContainerLow: AppColors.surfaceLightElevated,
    surfaceContainerHighest: Color(0xFFF0F4F7),
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.dividerLight,
    primaryContainer: Color(0xFFD8E7F2),
    onError: Colors.white,
  );

  static const _darkScheme = ColorScheme.dark(
    primary: AppColors.primaryLight,
    secondary: AppColors.secondary,
    surface: AppColors.surfaceDark,
    surfaceContainerLow: AppColors.surfaceDarkElevated,
    surfaceContainerHighest: Color(0xFF223243),
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.dividerDark,
    primaryContainer: Color(0xFF173450),
    onError: Colors.white,
  );

  static TextTheme _textTheme(
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: primary),
      headlineLarge: AppTypography.headline.copyWith(color: primary),
      titleLarge: AppTypography.title.copyWith(color: primary),
      titleMedium: AppTypography.subtitle.copyWith(color: primary),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: primary),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondary),
      labelLarge: AppTypography.label.copyWith(color: accent),
      labelSmall: AppTypography.overline.copyWith(color: secondary),
    );
  }

  static AppBarTheme _appBarTheme(Color foreground) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.title.copyWith(color: foreground),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color primary) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(AppDimens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        textStyle: AppTypography.label.copyWith(fontSize: 16),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.sm,
          horizontal: AppDimens.lg,
        ),
      ),
    );
  }
}
