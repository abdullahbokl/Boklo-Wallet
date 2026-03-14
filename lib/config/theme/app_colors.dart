import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F4C81);
  static const Color primaryDark = Color(0xFF0A365C);
  static const Color primaryLight = Color(0xFF3C729E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F4C81), Color(0xFF195E97)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color secondary = Color(0xFF1D7A85);
  static const Color secondaryDark = Color(0xFF155A62);
  static const Color accent = Color(0xFFC6922C);

  static const Color backgroundLight = Color(0xFFF4F6F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFF9FBFC);
  static const Color textPrimaryLight = Color(0xFF16202A);
  static const Color textSecondaryLight = Color(0xFF5D6B78);
  static const Color mutedLight = Color(0xFF8D99A6);
  static const Color borderLight = Color(0xFFD7DEE5);

  static const Color backgroundDark = Color(0xFF0F1820);
  static const Color surfaceDark = Color(0xFF16222D);
  static const Color surfaceDarkElevated = Color(0xFF1E2C39);
  static const Color textPrimaryDark = Color(0xFFF2F5F8);
  static const Color textSecondaryDark = Color(0xFFB0BCC8);
  static const Color mutedDark = Color(0xFF8292A0);
  static const Color borderDark = Color(0xFF273747);

  static const Color success = Color(0xFF198754);
  static const Color error = Color(0xFFBB3D3D);
  static const Color warning = Color(0xFFC0841A);
  static const Color info = Color(0xFF2F6EA6);

  static const Color glassLight = Color(0xF2FFFFFF);
  static const Color glassDark = Color(0xCC16222D);
  static const Color glassBorderLight = Color(0x52FFFFFF);
  static const Color glassBorderDark = Color(0x1FFFFFFF);

  static const Color shimmerBaseLight = Color(0xFFE3E8ED);
  static const Color shimmerHighlightLight = Color(0xFFF6F8FA);
  static const Color shimmerBaseDark = Color(0xFF2A3845);
  static const Color shimmerHighlightDark = Color(0xFF364858);

  static const Color dividerLight = borderLight;
  static const Color dividerDark = borderDark;

  static const Color pageTintLight = Color(0xFFEAF1F6);
  static const Color pageTintDark = Color(0xFF12212B);

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0C112030),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x12112030),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A112030),
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];
}
