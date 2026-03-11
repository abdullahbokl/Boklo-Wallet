import 'package:flutter/animation.dart';

/// Centralised animation constants for consistent motion across the app.
class AppAnimations {
  AppAnimations._();

  // ── Durations ──
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration entrance = Duration(milliseconds: 600);

  // ── Curves ──
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;

  /// Returns a staggered delay for list entrance animations.
  static Duration staggeredDelay(int index, {int baseMs = 50}) {
    return Duration(milliseconds: index * baseMs);
  }
}
