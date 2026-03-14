// Print statements are used for logging performance results to stdout.
// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:boklo/app.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'core/cold_start_helpers.dart';
import 'core/page_test_config.dart';
import 'core/perf_metrics.dart';
import 'core/perf_report.dart';
import 'core/stress_scroll.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/core/base/base_state.dart';

/// Runs a full cold-start + warm-start performance benchmark for a single page.
///
/// **Cold run**: Clears image cache, resets DI, pumps a fresh [MyApp],
/// navigates to the page, performs stress scrolling if configured,
/// and captures [FrameTiming] data.
///
/// **Warm run**: Navigates away and back without resetting DI,
/// to measure the improvement from cached shaders / images.
///
/// Returns a [PagePerfResult] with metrics for both runs and the delta.
Future<PagePerfResult> runPagePerfTest(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  PageTestConfig config,
) async {
  // ── Cold Run ──────────────────────────────────────────────────────────
  print('🧊 [${config.pageName}] Starting COLD run...');
  await simulateColdStart();

  // Pump a fresh app instance.
  await tester.pumpWidget(const MyApp());
  await tester.pump();
  try {
    // Only wait 2 seconds for initial bootstrap, don't hang on spinners.
    await tester.pumpAndSettle(const Duration(seconds: 2));
  } catch (_) {}

  // Capture frame timings during navigation + interaction.
  final coldTimings = await _captureFrameTimings(
    tester,
    binding,
    config,
  );

  final coldMetrics = PerfMetrics.fromFrameTimings(coldTimings);
  print('   Cold: $coldMetrics');

  // ── Warm Run ──────────────────────────────────────────────────────────
  print('🔥 [${config.pageName}] Starting WARM run...');

  // Navigate away first (to /login as a neutral page), then back.
  final navigationService = getIt<NavigationService>();
  final context = navigationService.navigatorKey.currentContext!;
  GoRouter.of(context).go('/login');
  await tester.pumpAndSettle();

  // Clear image cache but do NOT reset DI — simulates a "back navigation"
  // where shaders are already compiled but images might be evicted.
  clearImageCache();

  final warmTimings = await _captureFrameTimings(
    tester,
    binding,
    config,
  );

  final warmMetrics = PerfMetrics.fromFrameTimings(warmTimings);
  print('   Warm: $warmMetrics');

  // ── Delta ─────────────────────────────────────────────────────────────
  final delta = PerfDelta.compute(cold: coldMetrics, warm: warmMetrics);
  print(
    '   Δ build_p90: ${delta.buildP90ImprovementPct}%, '
    'raster_p90: ${delta.rasterP90ImprovementPct}%',
  );

  return PagePerfResult(
    cold: coldMetrics,
    warm: warmMetrics,
    delta: delta,
  );
}

/// Navigates to the configured route, waits for settle, and performs
/// stress scrolling — all while capturing [FrameTiming] data via
/// the binding's `addTimingsCallback` / `removeTimingsCallback`.
///
/// This gives us direct access to per-frame build and raster durations
/// for custom percentile computation, unlike `watchPerformance` which
/// only stores a summary map.
Future<List<FrameTiming>> _captureFrameTimings(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  PageTestConfig config,
) async {
  final collectedTimings = <FrameTiming>[];

  // Register our callback to collect frame timings.
  void onTimings(List<FrameTiming> timings) {
    collectedTimings.addAll(timings);
  }

  SchedulerBinding.instance.addTimingsCallback(onTimings);

  try {
    if (config.requiresAuth) {
      _mockAuthenticatedState();
      await tester.pump();
    }

    // Navigate to the target page.
    final context = getIt<NavigationService>().navigatorKey.currentContext!;
    GoRouter.of(context).go(
      config.routePath,
      extra: config.routeExtra,
    );

    // Initial transition wait.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); 

    // Settle as much as possible.
    try {
      await tester.pumpAndSettle(const Duration(seconds: 2)); 
    } catch (_) {}

    // Stress scroll if the page has scrollable content.
    if (config.hasScrollableContent) {
      print('   🏃 [${config.pageName}] Stress scrolling...');
      await stressScroll(
        tester,
        iterations: config.scrollIterations,
      );
    }

    // Final flush.
    await tester.pump(const Duration(milliseconds: 200));
    try {
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } catch (_) {}

    // Brief wait for engine to report last frames.
    await tester.pump(const Duration(milliseconds: 500));
  } finally {
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
  }

  return collectedTimings;
}

/// Force-injects a mock authenticated user into the AuthCubit.
void _mockAuthenticatedState() {
  final authCubit = getIt<AuthCubit>();
  const mockUser = User(
    id: 'perf-test-user',
    email: 'perf@test.com',
    displayName: 'Perf Test',
    username: 'perftest',
  );
  authCubit.emit(const BaseState.success(mockUser));
}
