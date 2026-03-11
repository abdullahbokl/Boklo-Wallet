import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountDetailsCard extends StatelessWidget {
  const AccountDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _SettingTile(
              icon: Icons.person_outline,
              title: 'Personal Info',
              onTap: () {
                // TODO(boklo): Implement personal info edit page
              },
            ),
            Divider(
              height: 1,
              indent: 56,
              color: scheme.outlineVariant,
            ),
            _SettingTile(
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              onTap: () => context.push('/notification-settings'),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: scheme.outlineVariant,
            ),
            _SettingTile(
              icon: Icons.security_outlined,
              title: 'Security',
              onTap: () {
                // TODO(boklo): Implement security settings
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
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
            Icon(icon, color: scheme.primary),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
