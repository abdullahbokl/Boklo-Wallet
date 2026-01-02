import 'package:boklo/shared/theme/tokens/app_typography.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData.light().copyWith(
    textTheme: AppTypography.textTheme,
  );

  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    textTheme: AppTypography.textTheme,
  );
}
