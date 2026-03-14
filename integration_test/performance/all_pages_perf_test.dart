// ignore_for_file: avoid_print

import 'package:boklo/core/config/emulator_config.dart';
import 'package:boklo/firebase_options_dev.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'core/page_test_config.dart';
import 'core/perf_report.dart';
import 'core/perf_test_binding.dart';
import 'page_perf_template.dart';

/// All-pages performance benchmark orchestrator.
///
/// Iterates over every page in the app one by one, runs cold + warm
/// benchmarks for each, and reports the aggregated JSON result to the
/// test driver for saving.
///
/// Usage:
/// ```bash
/// flutter drive \
///   --driver=test_driver/perf_driver.dart \
///   --target=integration_test/performance/all_pages_perf_test.dart \
///   --profile
/// ```
void main() {
  final binding = initPerfBinding();
  final report = PerfReport();

  // ── Page Configurations ───────────────────────────────────────────────
  // Add or remove pages here as the app evolves.
  // Pages are tested in order — unauthenticated pages first.
  const pages = <PageTestConfig>[
    PageTestConfig(
      pageName: 'LoginPage',
      routePath: '/login',
      hasScrollableContent: true,
      scrollIterations: 2,
    ),
    PageTestConfig(
      pageName: 'RegisterPage',
      routePath: '/register',
      hasScrollableContent: true,
      scrollIterations: 2,
    ),
    PageTestConfig(
      pageName: 'ProfileSetupPage',
      routePath: '/profile-setup',
      hasScrollableContent: true,
      scrollIterations: 3,
    ),

    // ── Authenticated Pages ──
    PageTestConfig(
      pageName: 'ProfilePage',
      routePath: '/profile',
      hasScrollableContent: true,
      scrollIterations: 3,
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'WalletPage',
      routePath: '/wallet',
      hasScrollableContent: true,
      scrollIterations: 5,
      settleTimeout: const Duration(seconds: 15),
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'TransferPage',
      routePath: '/transfer',
      hasScrollableContent: true,
      scrollIterations: 3,
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'LedgerDebugPage',
      routePath: '/ledger',
      hasScrollableContent: true,
      scrollIterations: 5,
      settleTimeout: const Duration(seconds: 15),
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'PaymentRequestListPage',
      routePath: '/payment-requests',
      hasScrollableContent: true,
      scrollIterations: 5,
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'CreatePaymentRequestPage',
      routePath: '/payment-requests/create',
      hasScrollableContent: true,
      scrollIterations: 3,
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'ContactListPage',
      routePath: '/contacts',
      hasScrollableContent: true,
      scrollIterations: 5,
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'NotificationSettingsPage',
      routePath: '/notification-settings',
      hasScrollableContent: true,
      scrollIterations: 3,
      requiresAuth: true,
    ),
    PageTestConfig(
      pageName: 'NotificationsPage',
      routePath: '/notifications',
      hasScrollableContent: true,
      scrollIterations: 5,
      requiresAuth: true,
    ),
  ];

  // ── Setup ─────────────────────────────────────────────────────────────
  setUpAll(() async {
    report.start();

    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Configure Emulators (crucial for local networking/auth)
    await EmulatorConfig.configure();

    print('');
    print('╔══════════════════════════════════════════════════════╗');
    print('║  🚀 Boklo Performance Benchmark Suite               ║');
    print('║  Pages: ${pages.length.toString().padRight(43)}║');
    print('╚══════════════════════════════════════════════════════╝');
    print('');
  });

  // ── Per-Page Tests ────────────────────────────────────────────────────
  for (final config in pages) {
    testWidgets(
      '${config.pageName} performance benchmark',
      (tester) async {
        final result = await runPagePerfTest(tester, binding, config);
        report.addPageResult(config.pageName, result);
        
        // Save incremental results in case subsequent tests crash
        binding.reportData = report.toJson();
      },
      timeout: Timeout(const Duration(minutes: 5)), // Increased timeout
    );
  }

  // ── Teardown & Report ─────────────────────────────────────────────────
  tearDownAll(() {
    report.finish();

    // Hand the aggregated JSON to the driver for saving.
    binding.reportData = report.toJson();

    print('');
    print('╔══════════════════════════════════════════════════════╗');
    print('║  ✅ Benchmark complete!                             ║');
    print('║  Results will be saved by the test driver.          ║');
    print('╚══════════════════════════════════════════════════════╝');
    print('');
  });
}
