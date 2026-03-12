import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_amount_input.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_balance_display.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_recipient_input.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: AppDimens.md, bottom: AppDimens.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TransferBalanceDisplay(wallet: wallet),
            const SizedBox(height: AppDimens.lg),
            AppCard(
              padding: const EdgeInsets.all(AppDimens.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    title: 'Transfer details',
                    subtitle: 'Enter who should receive the money and how much.',
                  ),
                  const SizedBox(height: AppDimens.lg),
                  TransferRecipientInput(
                    controller: recipientController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimens.lg),
                  TransferAmountInput(
                    controller: amountController,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: AppDimens.lg),
                  Text(
                    'Transfers are confirmed by the backend before balances update.',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xl),
                  AppButton(
                    onPressed: isLoading ? null : onSubmit,
                    text: 'Review transfer',
                    isLoading: isLoading,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
