import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/settings/presentation/bloc/theme_cubit.dart';
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

  String get label => switch (this) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
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
            title: 'Personal information',
            subtitle: 'Review the details linked to your Boklo account.',
            onTap: () {},
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          _SettingTile(
            icon: Icons.notifications_none_outlined,
            title: 'Notifications',
            subtitle: 'Choose which alerts Boklo should send you.',
            onTap: () => context.push('/notification-settings'),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          const _ThemeModeSection(),
          Divider(height: 1, color: scheme.outlineVariant),
          _SettingTile(
            icon: Icons.security_outlined,
            title: 'Security',
            subtitle: 'Security tools and protections for your wallet.',
            onTap: () {},
          ),
        ],
      ),
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
                        Text('Appearance', style: AppTypography.subtitle),
                        const SizedBox(height: AppDimens.xs4),
                        Text(
                          'Pick the look you want for Boklo.',
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
                          onTap: () => context
                              .read<ThemeCubit>()
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      Expanded(
                        child: _ThemeModeSegment(
                          mode: ThemeMode.system,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => context
                              .read<ThemeCubit>()
                              .setThemeMode(ThemeMode.system),
                        ),
                      ),
                      Expanded(
                        child: _ThemeModeSegment(
                          mode: ThemeMode.light,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => context
                              .read<ThemeCubit>()
                              .setThemeMode(ThemeMode.light),
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
                mode.label,
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
