import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

enum TransactionStatus { pending, completed, failed }

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.status,
    super.key,
  });

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, text, icon) = switch (status) {
      TransactionStatus.pending => (
          AppColors.warning,
          'Pending',
          Icons.schedule_rounded,
        ),
      TransactionStatus.completed => (
          AppColors.success,
          'Completed',
          Icons.check_circle_rounded,
        ),
      TransactionStatus.failed => (
          AppColors.error,
          'Failed',
          Icons.error_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppDimens.xs4),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
