import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// First-launch welcome carousel.
///
/// Shown once (flag persisted in secure storage) before the wallet tab
/// tree; skipping or finishing both mark onboarding complete.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const seenKey = 'ONBOARDING_SEEN';

  /// Synchronous gate consulted by the router's redirect. Loaded from
  /// storage during bootstrap (before runApp); defaults to true so a
  /// storage failure can never trap users in onboarding.
  static bool hasCompleted = true;

  /// Whether this device has already completed onboarding.
  static Future<bool> hasSeen() async {
    try {
      return await const FlutterSecureStorage().read(key: seenKey) == 'true';
    } on Object {
      return true; // fail open: never trap users in onboarding
    }
  }

  static Future<void> loadFlag() async {
    hasCompleted = await hasSeen();
  }

  static Future<void> markSeen() async {
    hasCompleted = true;
    try {
      await const FlutterSecureStorage().write(key: seenKey, value: 'true');
    } on Object {
      // Non-critical; the carousel may show again on next launch.
    }
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPage.markSeen();
    if (!mounted) return;
    getIt<NavigationService>().go('/wallet');
  }

  void _next() {
    if (_index == 2) {
      unawaited(_finish());
      return;
    }
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final slides = <(_IconBadge, String, String)>[
      (
        const _IconBadge(icon: Icons.account_balance_wallet_outlined),
        l10n.onboarding1Title,
        l10n.onboarding1Body,
      ),
      (
        const _IconBadge(icon: Icons.send_rounded),
        l10n.onboarding2Title,
        l10n.onboarding2Body,
      ),
      (
        const _IconBadge(icon: Icons.insights_rounded),
        l10n.onboarding3Title,
        l10n.onboarding3Body,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.md),
                child: TextButton(
                  onPressed: () => unawaited(_finish()),
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final (badge, title, body) = slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppDimens.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        badge,
                        const SizedBox(height: AppDimens.xxl),
                        Text(title, style: AppTypography.display),
                        const SizedBox(height: AppDimens.lg),
                        Text(
                          body,
                          style: AppTypography.bodyLarge.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimens.xs4,
                  ),
                  width: i == _index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.xl),
              child: AppButton(
                text: _index == slides.length - 1
                    ? l10n.onboardingGetStarted
                    : l10n.onboardingNext,
                width: double.infinity,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xxl),
        child: Icon(icon, size: 56, color: scheme.primary),
      ),
    );
  }
}
