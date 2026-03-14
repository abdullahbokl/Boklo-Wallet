import 'perf_metrics.dart';

/// Aggregated performance report across all tested pages.
///
/// Collects [PagePerfResult] entries and serializes them into a
/// structured JSON map suitable for `IntegrationTestWidgetsFlutterBinding.reportData()`.
class PerfReport {
  PerfReport();

  final Map<String, PagePerfResult> _results = {};
  DateTime? _startTime;
  DateTime? _endTime;

  /// Marks the beginning of the benchmark run.
  void start() => _startTime = DateTime.now();

  /// Marks the end of the benchmark run.
  void finish() => _endTime = DateTime.now();

  /// Adds a result for the given [pageName].
  void addPageResult(String pageName, PagePerfResult result) {
    _results[pageName] = result;
  }

  Map<String, dynamic> toJson() {
    final pages = <String, dynamic>{};
    final jankReport = <Map<String, dynamic>>[];
    const jankThresholdMs = 16.0; // Threshold for 60fps jank

    for (final entry in _results.entries) {
      pages[entry.key] = entry.value.toJson();
      final cold = entry.value.cold;
      final warm = entry.value.warm;

      // Check Build Thread (UI)
      if (cold.frameBuildP99Ms > jankThresholdMs) {
        jankReport.add({
          'page': entry.key,
          'thread': 'UI/Build',
          'cold_p99_ms': PerfMetrics.round2(cold.frameBuildP99Ms),
          'warm_p99_ms': PerfMetrics.round2(warm.frameBuildP99Ms),
        });
      }

      // Check Raster Thread (GPU)
      if (cold.frameRasterP99Ms > jankThresholdMs) {
        jankReport.add({
          'page': entry.key,
          'thread': 'GPU/Raster',
          'cold_p99_ms': PerfMetrics.round2(cold.frameRasterP99Ms),
          'warm_p99_ms': PerfMetrics.round2(warm.frameRasterP99Ms),
        });
      }
    }

    // Sort jankReport by cold_p99_ms descending
    jankReport.sort((a, b) => (b['cold_p99_ms'] as double).compareTo(a['cold_p99_ms'] as double));

    return {
      'generated_at': (_endTime ?? DateTime.now()).toIso8601String(),
      'duration_seconds': _startTime != null && _endTime != null
          ? _endTime!.difference(_startTime!).inSeconds
          : null,
      'pages': pages,
      'summary': {
        'total_pages_tested': _results.length,
        'jank_count': jankReport.length,
        'jank_report': jankReport,
      },
    };
  }
}

/// Performance result for a single page, containing cold and warm metrics.
class PagePerfResult {
  const PagePerfResult({
    required this.cold,
    required this.warm,
    required this.delta,
  });

  final PerfMetrics cold;
  final PerfMetrics warm;
  final PerfDelta delta;

  Map<String, dynamic> toJson() => {
        'cold': cold.toJson(),
        'warm': warm.toJson(),
        'delta': delta.toJson(),
      };
}
