import 'package:boklo/config/theme/app_dimens.dart';
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    this.child,
    this.stackChildren,
  });

  final Widget? child;
  final List<Widget>? stackChildren;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            scheme.surface,
            scheme.surface,
          ],
          stops: const [0, 0.3, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -20,
            child: _GlowOrb(
              size: 180,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -50,
            bottom: 60,
            child: _GlowOrb(
              size: 140,
              color: scheme.secondary.withValues(alpha: 0.08),
            ),
          ),
          if (stackChildren != null) ...stackChildren!,
          if (child != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.pageHorizontalPadding,
                ),
                child: child!,
              ),
            ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
