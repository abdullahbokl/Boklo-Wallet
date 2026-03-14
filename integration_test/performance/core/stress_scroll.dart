import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performs automated stress scrolling to surface raster jank during movement.
///
/// Finds the first [Scrollable] in the widget tree (or uses [scrollable]
/// if provided), then performs [iterations] fling gestures alternating
/// between down and up directions.
///
/// Each fling:
/// - Uses a velocity of [speed] pixels/second
/// - Waits for the scroll to settle before the next fling
///
/// This simulates a real user rapidly scrolling through a list, which is
/// the most common source of Impeller first-frame shader compilation jank.
Future<void> stressScroll(
  WidgetTester tester, {
  Finder? scrollable,
  int iterations = 5,
  double speed = 3000,
}) async {
  final effectiveFinder = scrollable ?? find.byType(Scrollable);
  
  if (!tester.any(effectiveFinder)) {
    print('      ⚠️  No Scrollable found on this page. Skipping stress scroll.');
    return;
  }

  final target = effectiveFinder.first;

  for (var i = 0; i < iterations; i++) {
    // Scroll down
    await tester.fling(
      target,
      const Offset(0, -500),
      speed,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // Scroll back up
    await tester.fling(
      target,
      const Offset(0, 500),
      speed,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
}
