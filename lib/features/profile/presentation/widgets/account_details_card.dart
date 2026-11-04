import 'dart:async';

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/app_lock_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/profile/presentation/widgets/account_info_sheet.dart';
import 'package:boklo/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:boklo/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// --- DART 3 EXTENSION: Cleaner abstraction than loose helper functions ---
extension on ThemeMode {
  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };

  Color color(ColorScheme scheme) => switch (this) {
    ThemeMode.system => scheme.secondary,
    ThemeMode.light => AppColors.accent,
    ThemeMode.dark => scheme.primary,
  };
}

class AccountDetailsCard extends StatelessWidget {
  const AccountDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.person_outline_rounded,
            title: context.l10n.personalInformation,
            subtitle: context.l10n.personalInformationSubtitle,
            onTap: () => _showAccountInfoSheet(context),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          _SettingTile(
            icon: Icons.notifications_none_outlined,
            title: context.l10n.notifications,
            subtitle: context.l10n.notificationsSubtitle,
            onTap: () => context.push('/notification-settings'),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          const _ThemeModeSection(),
          Divider(height: 1, color: scheme.outlineVariant),
          const _LanguageSection(),
          Divider(height: 1, color: scheme.outlineVariant),
          const _AppLockSection(),
        ],
      ),
    );
  }

  Future<void> _showAccountInfoSheet(BuildContext context) async {
    final user = context.read<AuthCubit>().state.data;
    if (user == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => AccountInfoSheet(user: user),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final scheme = Theme.of(context).colorScheme;
        final activeColor = themeMode.color(scheme);

        return Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // FLATTENED: DecoratedBox + Padding instead of Container
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.sm),
                      child: Icon(themeMode.icon, color: activeColor),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.appearance,
                          style: AppTypography.subtitle,
                        ),
                        const SizedBox(height: AppDimens.xs4),
                        Text(
                          context.l10n.themePickLook,
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              // FLATTENED: DecoratedBox + Padding
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.xs4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ThemeModeSegment(
                          mode: ThemeMode.dark,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => context.read<ThemeCubit>().setThemeMode(
                            ThemeMode.dark,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ThemeModeSegment(
                          mode: ThemeMode.system,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => context.read<ThemeCubit>().setThemeMode(
                            ThemeMode.system,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ThemeModeSegment(
                          mode: ThemeMode.light,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => context.read<ThemeCubit>().setThemeMode(
                            ThemeMode.light,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeModeSegment extends StatelessWidget {
  const _ThemeModeSegment({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = mode.color(scheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.xs,
            vertical: AppDimens.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FLATTENED: DecoratedBox + SizedBox
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(
                    mode.icon,
                    color: accentColor,
                    size: 18,
                  ), // Explicit size helps layout
                ),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                mode.label(context.l10n),
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? accentColor : scheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimens.xs4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : scheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<LocaleCubit, Locale?>(
      builder: (context, locale) {
        return Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.sm),
                      child: Icon(
                        Icons.language_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.language,
                          style: AppTypography.subtitle,
                        ),
                        const SizedBox(height: AppDimens.xs4),
                        Text(
                          context.l10n.languageSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.xs4),
                  child: Row(
                    children: [
                      _LanguageSegment(
                        label: context.l10n.languageSystem,
                        isSelected: locale == null,
                        onTap: () =>
                            context.read<LocaleCubit>().setLanguageCode(null),
                      ),
                      _LanguageSegment(
                        label: context.l10n.languageEnglish,
                        isSelected: locale?.languageCode == 'en',
                        onTap: () =>
                            context.read<LocaleCubit>().setLanguageCode('en'),
                      ),
                      _LanguageSegment(
                        label: context.l10n.languageArabic,
                        isSelected: locale?.languageCode == 'ar',
                        onTap: () =>
                            context.read<LocaleCubit>().setLanguageCode('ar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageSegment extends StatelessWidget {
  const _LanguageSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = scheme.primary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.xs,
              vertical: AppDimens.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected ? accentColor : scheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimens.xs4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppLockSection extends StatefulWidget {
  const _AppLockSection();

  @override
  State<_AppLockSection> createState() => _AppLockSectionState();
}

class _AppLockSectionState extends State<_AppLockSection> {
  final AppLockService _service = getIt<AppLockService>();

  bool? _enabled;
  bool _available = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final enabled = await _service.isEnabled();
    final available = await _service.canAuthenticate();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _available = available;
    });
  }

  Future<void> _toggle(bool value) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (value) {
      // Confirm the user can actually authenticate before enabling,
      // otherwise the gate would lock them out permanently.
      final ok = await _service.authenticate();
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.appLockUnavailable)),
        );
        return;
      }
    }
    await _service.setEnabled(enabled: value);
    if (mounted) setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = _enabled ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.sm),
              child: Icon(Icons.fingerprint_rounded, color: scheme.primary),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.appLock, style: AppTypography.subtitle),
                const SizedBox(height: AppDimens.xs4),
                Text(
                  _available
                      ? context.l10n.appLockSubtitle
                      : context.l10n.appLockUnavailable,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            onChanged: _available ? (value) => unawaited(_toggle(value)) : null,
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      // Ensures ripples paint cleanly inside the custom card
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Row(
            children: [
              // FLATTENED: DecoratedBox + Padding
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.sm),
                  child: Icon(icon, color: scheme.primary),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.subtitle),
                    const SizedBox(height: AppDimens.xs4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
