import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget? child;
  final List<Widget>? stackChildren;

  const AuthBackground({
    super.key,
    this.child,
    this.stackChildren,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.1),
            scheme.primaryContainer.withValues(alpha: 0.05),
            scheme.surface,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (stackChildren != null) ...stackChildren!,
          if (child != null) SafeArea(child: child!),
        ],
      ),
    );
  }
}
