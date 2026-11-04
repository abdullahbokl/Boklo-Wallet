import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/app_lock_service.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

/// Wraps the authenticated app and blocks it behind local authentication
/// while [AppLockService.isLocked] is true.
///
/// Locks on lifecycle pause (app leaves foreground), unlocks only after a
/// successful [AppLockService.authenticate]. If the preference is disabled
/// the child renders directly.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final AppLockService _service = getIt<AppLockService>();

  bool? _enabled;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadPreference());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadPreference() async {
    final enabled = await _service.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      // Cold start with the lock enabled also starts locked.
      _service.isLocked = enabled;
    });
    if (enabled) {
      await _promptAuth();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_enabled != true) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _service.isLocked = true;
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _service.isLocked) {
      unawaited(_promptAuth());
    }
  }

  Future<void> _promptAuth() async {
    if (_authenticating || !mounted) return;
    _authenticating = true;
    final success = await _service.authenticate();
    _authenticating = false;
    if (!mounted) return;
    if (success) {
      _service.isLocked = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled != true || !_service.isLocked) {
      return widget.child;
    }
    return _LockScreen(onUnlock: _promptAuth);
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: scheme.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                Text(
                  context.l10n.appLockLockedTitle,
                  style: AppTypography.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  context.l10n.appLockLockedBody,
                  style: AppTypography.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.xl),
                AppButton(
                  text: context.l10n.appLockUnlock,
                  onPressed: () => unawaited(onUnlock()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
