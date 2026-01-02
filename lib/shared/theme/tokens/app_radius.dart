import 'package:flutter/painting.dart';

class AppRadius {
  static const double s = 4;
  static const double m = 8;
  static const double l = 16;
  static const double xl = 24;
  static const double full = 999;

  static const Radius small = Radius.circular(s);
  static const Radius medium = Radius.circular(m);
  static const Radius large = Radius.circular(l);
  static const Radius extraLarge = Radius.circular(xl);

  static const BorderRadius smallAll = BorderRadius.all(small);
  static const BorderRadius mediumAll = BorderRadius.all(medium);
  static const BorderRadius largeAll = BorderRadius.all(large);
  static const BorderRadius extraLargeAll = BorderRadius.all(extraLarge);
}
