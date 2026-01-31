import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:flutter/material.dart';

class TransferConfirmationDialog extends StatelessWidget {
  const TransferConfirmationDialog({
    required this.amount,
    required this.currency,
    required this.recipient,
    required this.onConfirm,
    super.key,
  });

  final double amount;
  final String currency;
  final String recipient;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Transfer', style: AppTypography.headline),
      content: Text(
        'Send $amount $currency to $recipient?',
        style: AppTypography.bodyMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      actions: [
        TextButton(
          onPressed: () => getIt<NavigationService>().pop(),
          child: Text(
            'Cancel',
            style: AppTypography.label
                .copyWith(color: AppColors.textSecondaryLight),
          ),
        ),
        TextButton(
          onPressed: () {
            getIt<NavigationService>().pop();
            onConfirm();
          },
          child: Text(
            'Confirm',
            style: AppTypography.label.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
