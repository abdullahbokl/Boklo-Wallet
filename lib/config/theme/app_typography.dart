import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get headline => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get title => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get subtitle => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get label => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get overline => GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 1.0,
      );
}
