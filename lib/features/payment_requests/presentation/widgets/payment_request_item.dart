import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentRequestItem extends StatelessWidget {
  const PaymentRequestItem({
    required this.request,
    this.isLoading = false,
    this.isOutgoing = false,
    super.key,
  });

  final PaymentRequestEntity request;
  final bool isLoading;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.amount} ${request.currency}',
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppDimens.xs),
                    Text(
                      isOutgoing 
                          ? 'To: ${request.payerId}' 
                          : 'From: ${request.requesterId}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                _StatusChip(status: request.status),
              ],
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: AppDimens.sm),
              Text(
                request.note!,
                style: AppTypography.bodyMedium,
              ),
            ],
            if (!isOutgoing && request.status == PaymentRequestStatus.pending) ...[
              const SizedBox(height: AppDimens.md),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Decline',
                      icon: Icons.close,
                      color: AppColors.error,
                      onPressed: isLoading 
                          ? null 
                          : () => context.read<PaymentRequestCubit>().declineRequest(request.id),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: _ActionButton(
                      label: 'Accept',
                      icon: Icons.check,
                      color: AppColors.success,
                      isPrimary: true,
                      isLoading: isLoading,
                      onPressed: isLoading 
                          ? null 
                          : () => context.read<PaymentRequestCubit>().acceptRequest(request.id),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final PaymentRequestStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case PaymentRequestStatus.pending:
        color = AppColors.warning;
        break;
      case PaymentRequestStatus.accepted:
        color = AppColors.success;
        break;
      case PaymentRequestStatus.declined:
        color = AppColors.error;
        break;
      case PaymentRequestStatus.invalid:
        color = AppColors.textSecondaryLight;
        break;
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: isPrimary ? 0.3 : 0.1),
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppDimens.xs),
                Text(
                  label,
                  style: AppTypography.label.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
