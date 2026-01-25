import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Primary Gradient (Deep Indigo -> Violet)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo to Violet
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary / Accents (Teal/Cyan)
  static const Color secondary = Color(0xFF06B6D4); // Cyan 500
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color accent = Color(0xFF14B8A6); // Teal 500

  // Neutral / Surface
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500

  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // Semantic
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -1),
    BoxShadow(
        color: Color(0x10000000),
        offset: Offset(0, 2),
        blurRadius: 4,
        spreadRadius: -1),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 10),
        blurRadius: 15,
        spreadRadius: -3),
    BoxShadow(
        color: Color(0x10000000),
        offset: Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -2),
  ];
}
