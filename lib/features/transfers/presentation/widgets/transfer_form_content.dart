import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_amount_input.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_balance_display.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_recipient_input.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

class TransferFormContent extends StatelessWidget {
  const TransferFormContent({
    required this.formKey,
    required this.wallet,
    required this.recipientController,
    required this.amountController,
    required this.isLoading,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final WalletEntity wallet;
  final TextEditingController recipientController;
  final TextEditingController amountController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransferBalanceDisplay(wallet: wallet),
            const SizedBox(height: AppDimens.xl),
            TransferRecipientInput(
              controller: recipientController,
              enabled: !isLoading,
            ),
            const SizedBox(height: AppDimens.md),
            TransferAmountInput(
              controller: amountController,
              enabled: !isLoading,
            ),
            const SizedBox(height: AppDimens.xl),
            SizedBox(
              height: 56, // Large touch target
              child: AppButton(
                onPressed: isLoading ? null : onSubmit,
                text: 'Confirm Transfer',
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
