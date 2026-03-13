import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/molecules/summary_item.dart';
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

  static Future<void> show({
    required BuildContext context,
    required double amount,
    required String currency,
    required String recipient,
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TransferConfirmationDialog(
        amount: amount,
        currency: currency,
        recipient: recipient,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      padding: const EdgeInsets.all(AppDimens.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.lg),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
              ),
            ),
            Text(
              'Confirm Transfer',
              style: AppTypography.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.xl),
            SummaryItem(
              label: 'Amount',
              value: '$amount $currency',
              isPrimary: true,
            ),
            const Divider(height: AppDimens.xl),
            SummaryItem(
              label: 'Recipient',
              value: recipient,
            ),
            const SizedBox(height: AppDimens.xxl),
            AppButton(
              text: 'Confirm & Send',
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
            ),
            const SizedBox(height: AppDimens.sm),
            AppButton(
              text: 'Cancel',
              isSecondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
