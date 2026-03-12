import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    required this.onSendTap,
    required this.onPaymentRequestsTap,
    required this.onContactsTap,
    required this.onNotificationsTap,
    super.key,
  });

  final VoidCallback onSendTap;
  final VoidCallback onPaymentRequestsTap;
  final VoidCallback onContactsTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionItem(
              icon: Icons.arrow_upward_rounded,
              label: 'Send',
              tone: scheme.primary,
              onTap: onSendTap,
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: _QuickActionItem(
              icon: Icons.request_quote_rounded,
              label: 'Request',
              tone: scheme.secondary,
              onTap: onPaymentRequestsTap,
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: _QuickActionItem(
              icon: Icons.people_alt_outlined,
              label: 'Contacts',
              tone: scheme.primary,
              onTap: onContactsTap,
            ),
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: _QuickActionItem(
              icon: Icons.notifications_outlined,
              label: 'Alerts',
              tone: scheme.tertiary,
              onTap: onNotificationsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.md,
            horizontal: AppDimens.xs,
          ),
          child: Column(
            children: [
              Icon(icon, color: tone, size: AppDimens.iconLg),
              const SizedBox(height: AppDimens.xs),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
