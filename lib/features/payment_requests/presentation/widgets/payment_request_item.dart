import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/payment_request_action_button.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/payment_request_status_chip.dart';
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
                PaymentRequestStatusChip(status: request.status),
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
                    child: PaymentRequestActionButton(
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
                    child: PaymentRequestActionButton(
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

