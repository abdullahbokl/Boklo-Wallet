import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimens.dart';
import '../../../../config/theme/app_typography.dart';

enum TransactionStatus { pending, completed, failed }

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String text;
    late IconData icon;

    switch (status) {
      case TransactionStatus.pending:
        color = AppColors.warning;
        text = 'Pending';
        icon = Icons.access_time_rounded;
        break;
      case TransactionStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case TransactionStatus.failed:
        color = AppColors.error;
        text = 'Failed';
        icon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
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
