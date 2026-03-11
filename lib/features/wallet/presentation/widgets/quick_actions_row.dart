import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onSendTap;
  final VoidCallback onPaymentRequestsTap;
  final VoidCallback onContactsTap;
  final VoidCallback onNotificationsTap;

  const QuickActionsRow({
    super.key,
    required this.onSendTap,
    required this.onPaymentRequestsTap,
    required this.onContactsTap,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.md,
        horizontal: AppDimens.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionItem(
            icon: Icons.send_rounded,
            label: 'Send',
            color: AppColors.primary,
            onTap: onSendTap,
          ),
          _QuickActionItem(
            icon: Icons.move_to_inbox_rounded,
            label: 'Request',
            color: AppColors.secondary,
            onTap: onPaymentRequestsTap,
          ),
          _QuickActionItem(
            icon: Icons.people_alt_rounded,
            label: 'Contacts',
            color: AppColors.success,
            onTap: onContactsTap,
          ),
          _QuickActionItem(
            icon: Icons.notifications_active_rounded,
            label: 'Alerts',
            color: AppColors.warning,
            onTap: onNotificationsTap,
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.xs,
          vertical: AppDimens.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              label,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
