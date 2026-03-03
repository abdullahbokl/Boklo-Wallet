import 'package:flutter/material.dart';

/// Wraps content with a max-width constraint and centers it.
/// Use this on page bodies to prevent stretching on large screens.
///
/// On screens narrower than [maxWidth], content fills the full width.
/// On screens wider than [maxWidth], content is centered with capped width.
class ResponsiveConstraint extends StatelessWidget {
  const ResponsiveConstraint({
    required this.child,
    super.key,
    this.maxWidth = 600,
    this.padding,
  });

  /// The maximum width the content can occupy.
  final double maxWidth;

  /// The child widget to constrain.
  final Widget child;

  /// Optional padding around the constrained content.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child:
            padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}
