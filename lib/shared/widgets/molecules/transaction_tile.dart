import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimens.dart';
import '../../../../config/theme/app_typography.dart';
import '../atoms/status_chip.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.isCredit,
    super.key,
  });

  final String title;
  final String amount;
  final String date;
  final TransactionStatus status;
  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: AppColors.shadowSm,
        border:
            Border.all(color: AppColors.textSecondaryLight.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimens.sm),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  date,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}$amount',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isCredit ? AppColors.success : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              StatusChip(status: status),
            ],
          ),
        ],
      ),
    );
  }
}
