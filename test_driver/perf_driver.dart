// Saves performance data from integration tests to a JSON file.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Performance test driver that connects to the integration test,
/// retrieves the performance summary JSON, and writes it to disk.
///
/// Usage:
/// ```bash
/// flutter drive \
///   --driver=test_driver/perf_driver.dart \
///   --target=integration_test/performance/all_pages_perf_test.dart \
///   --profile
/// ```
Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      print('📥 Driver received data from test...');
      if (data == null || data.isEmpty) {
        print('⚠️  No performance data received from the integration test.');
        return;
      }

      final outputDir = Directory('build/perf_results');
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final outputFile = File('${outputDir.path}/performance_summary.json');
      final encoder = const JsonEncoder.withIndent('  ');
      await outputFile.writeAsString(encoder.convert(data));

      print('');
      print('╔══════════════════════════════════════════════════════╗');
      print('║  ✅ Performance summary saved to:                   ║');
      print('║  ${outputFile.path.padRight(51)}║');
      print('╚══════════════════════════════════════════════════════╝');
      print('');
    },
  );
}
