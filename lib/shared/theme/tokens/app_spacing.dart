import 'package:boklo/shared/responsive/screen_info.dart';

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Returns a spacing value based on the current screen size.
  /// Defaults to [m] if no specific value is provided.
  static double responsive(
    ScreenInfo info, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    if (info.isDesktop && desktop != null) return desktop;
    if (info.isTablet && tablet != null) return tablet;
    if (info.isMobile && mobile != null) return mobile;
    return m;
  }
}
