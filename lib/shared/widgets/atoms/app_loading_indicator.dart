import 'package:flutter/material.dart';

/// A consistent loading indicator used across the app.
///
/// Defaults to a centered, circular progress indicator that matches the current
/// color scheme. Override [center], [size], or [strokeWidth] when needed.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.center = true,
    this.size = 24.0,
    this.strokeWidth = 2.5,
    this.color,
  });

  final bool center;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget indicator = RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );

    return center ? Center(child: indicator) : indicator;
  }
}
