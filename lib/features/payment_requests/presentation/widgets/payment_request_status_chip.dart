import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:flutter/material.dart';

class PaymentRequestStatusChip extends StatelessWidget {
  const PaymentRequestStatusChip({
    required this.status,
    super.key,
  });

  final PaymentRequestStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case PaymentRequestStatus.pending:
        color = AppColors.warning;
      case PaymentRequestStatus.accepted:
        color = AppColors.success;
      case PaymentRequestStatus.declined:
        color = AppColors.error;
      case PaymentRequestStatus.invalid:
        color = AppColors.textSecondaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.sm,
        vertical: AppDimens.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
