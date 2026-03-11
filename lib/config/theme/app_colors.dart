import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Gradient (Deep Indigo → Violet) ──
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF818CF8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Secondary / Accents ──
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color accent = Color(0xFF14B8A6);

  // ── Light Surfaces ──
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // ── Dark Surfaces ──
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDarkElevated = Color(0xFF283548);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ── Semantic ──
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Glassmorphism ──
  static const Color glassLight = Color(0xCCFFFFFF);
  static const Color glassDark = Color(0x801E293B);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x1AFFFFFF);

  // ── Shimmer ──
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);
  static const Color shimmerBaseDark = Color(0xFF334155);
  static const Color shimmerHighlightDark = Color(0xFF475569);

  // ── Divider ──
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // ── Shadows ──
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x10000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x10000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];
}
