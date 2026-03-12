import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

        return Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.sm),
                    decoration: BoxDecoration(
                      color: _themeModeColor(context, themeMode).withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Icon(
                      _themeModeIcon(themeMode),
                      color: _themeModeColor(context, themeMode),
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
              Container(
                padding: const EdgeInsets.all(AppDimens.xs4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: scheme.outlineVariant),
                ),
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
    final accentColor = _themeModeColor(context, mode);

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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(_themeModeIcon(mode), color: accentColor),
              ),
              const SizedBox(height: AppDimens.xs),
              Text(
                _themeModeLabel(mode),
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

IconData _themeModeIcon(ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
  };
}

String _themeModeLabel(ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

Color _themeModeColor(BuildContext context, ThemeMode themeMode) {
  final scheme = Theme.of(context).colorScheme;

  return switch (themeMode) {
    ThemeMode.system => scheme.secondary,
    ThemeMode.light => AppColors.accent,
    ThemeMode.dark => scheme.primary,
  };
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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(icon, color: scheme.primary),
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
    );
  }
}
