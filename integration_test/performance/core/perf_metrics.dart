import 'dart:math';
import 'dart:ui';

/// Performance KPI metrics computed from a list of [FrameTiming] samples.
///
/// Tracks the 90th and 99th percentile for both frame build (UI thread)
/// and frame rasterizer (GPU thread) durations.
class PerfMetrics {
  const PerfMetrics({
    required this.frameBuildP90Ms,
    required this.frameBuildP99Ms,
    required this.frameRasterP90Ms,
    required this.frameRasterP99Ms,
    required this.totalFrames,
  });

  /// Computes metrics from raw [FrameTiming] data.
  factory PerfMetrics.fromFrameTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) {
      return const PerfMetrics(
        frameBuildP90Ms: 0,
        frameBuildP99Ms: 0,
        frameRasterP90Ms: 0,
        frameRasterP99Ms: 0,
        totalFrames: 0,
      );
    }

    final buildDurations = timings
        .map((t) => t.buildDuration.inMicroseconds / 1000.0)
        .toList()
      ..sort();

    final rasterDurations = timings
        .map((t) => t.rasterDuration.inMicroseconds / 1000.0)
        .toList()
      ..sort();

    return PerfMetrics(
      frameBuildP90Ms: _percentile(buildDurations, 0.90),
      frameBuildP99Ms: _percentile(buildDurations, 0.99),
      frameRasterP90Ms: _percentile(rasterDurations, 0.90),
      frameRasterP99Ms: _percentile(rasterDurations, 0.99),
      totalFrames: timings.length,
    );
  }

  final double frameBuildP90Ms;
  final double frameBuildP99Ms;
  final double frameRasterP90Ms;
  final double frameRasterP99Ms;
  final int totalFrames;

  /// Serializes to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'frame_build_time_p90_ms': round2(frameBuildP90Ms),
        'frame_build_time_p99_ms': round2(frameBuildP99Ms),
        'frame_raster_time_p90_ms': round2(frameRasterP90Ms),
        'frame_raster_time_p99_ms': round2(frameRasterP99Ms),
        'total_frames': totalFrames,
      };

  @override
  String toString() =>
      'PerfMetrics(build_p90=${round2(frameBuildP90Ms)}ms, '
      'build_p99=${round2(frameBuildP99Ms)}ms, '
      'raster_p90=${round2(frameRasterP90Ms)}ms, '
      'raster_p99=${round2(frameRasterP99Ms)}ms, '
      'frames=$totalFrames)';

  /// Computes the [p]th percentile (0.0–1.0) from a **sorted** list.
  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    final index = ((sorted.length - 1) * p).ceil();
    return sorted[min(index, sorted.length - 1)];
  }

  /// Rounds to 2 decimal places for readable JSON output.
  static double round2(double v) =>
      (v * 100).roundToDouble() / 100;
}

/// Delta between cold-start and warm-start metrics.
class PerfDelta {
  const PerfDelta({
    required this.buildP90ImprovementPct,
    required this.buildP99ImprovementPct,
    required this.rasterP90ImprovementPct,
    required this.rasterP99ImprovementPct,
  });

  /// Computes the percentage improvement from [cold] → [warm].
  ///
  /// Positive values mean warm is faster (improvement).
  /// Negative values mean warm is slower (regression).
  factory PerfDelta.compute({
    required PerfMetrics cold,
    required PerfMetrics warm,
  }) {
    return PerfDelta(
      buildP90ImprovementPct: _pctDiff(cold.frameBuildP90Ms, warm.frameBuildP90Ms),
      buildP99ImprovementPct: _pctDiff(cold.frameBuildP99Ms, warm.frameBuildP99Ms),
      rasterP90ImprovementPct: _pctDiff(cold.frameRasterP90Ms, warm.frameRasterP90Ms),
      rasterP99ImprovementPct: _pctDiff(cold.frameRasterP99Ms, warm.frameRasterP99Ms),
    );
  }

  final double buildP90ImprovementPct;
  final double buildP99ImprovementPct;
  final double rasterP90ImprovementPct;
  final double rasterP99ImprovementPct;

  Map<String, dynamic> toJson() => {
        'build_p90_improvement_pct': _roundPct(buildP90ImprovementPct),
        'build_p99_improvement_pct': _roundPct(buildP99ImprovementPct),
        'raster_p90_improvement_pct': _roundPct(rasterP90ImprovementPct),
        'raster_p99_improvement_pct': _roundPct(rasterP99ImprovementPct),
      };

  /// Percentage difference: positive = improvement, negative = regression.
  static double _pctDiff(double cold, double warm) {
    if (cold == 0) return 0;
    return ((cold - warm) / cold) * 100;
  }

  static double _roundPct(double v) =>
      (v * 10).roundToDouble() / 10;
}
