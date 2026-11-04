import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/data/repositories/scheduled_transfer_repository_impl.dart';
import 'package:boklo/features/transfers/domain/entities/scheduled_transfer_entity.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_amount_input.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_balance_display.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_favorites_row.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_fee_note.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_recipient_input.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
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

  /// Captures the current recipient + amount as a recurring transfer.
  Future<void> _scheduleTransfer(BuildContext context) async {
    final l10n = context.l10n;
    final scaffold = ScaffoldMessenger.of(context);

    final frequency = await showDialog<ScheduleFrequency>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.scheduleFrequencyPrompt),
        children: [
          for (final frequency in ScheduleFrequency.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(frequency),
              child: Text(
                switch (frequency) {
                  ScheduleFrequency.daily => l10n.scheduledDaily,
                  ScheduleFrequency.weekly => l10n.scheduledWeekly,
                  ScheduleFrequency.monthly => l10n.scheduledMonthly,
                },
              ),
            ),
        ],
      ),
    );
    if (frequency == null) return;

    final recipient = recipientController.text.trim();
    final amountMinor = tryParseMoney(amountController.text);
    if (recipient.isEmpty || amountMinor == null) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.scheduleCreateFailed)),
      );
      return;
    }

    final result = await getIt<ScheduledTransferRepository>().createSchedule(
      toWalletId: recipient,
      amountMinor: amountMinor,
      currency: wallet.currency,
      frequency: frequency,
    );
    result.fold(
      (_) => scaffold.showSnackBar(
        SnackBar(content: Text(l10n.scheduleCreateFailed)),
      ),
      (_) => scaffold.showSnackBar(
        SnackBar(content: Text(l10n.scheduleCreated)),
      ),
    );
  }

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
                  AppSectionHeader(
                    title: context.l10n.transferDetails,
                    subtitle: context.l10n.transferFormSubtitle,
                  ),
                  const SizedBox(height: AppDimens.lg),
                  TransferFavoritesRow(
                    onSelected: (contact) {
                      recipientController.text = contact.email;
                    },
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
                  TransferFeeNote(
                    amountController: amountController,
                    currency: wallet.currency,
                  ),
                  const SizedBox(height: AppDimens.lg),
                  Text(
                    context.l10n.transferBackendNote,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xl),
                  AppButton(
                    onPressed: isLoading ? null : onSubmit,
                    text: context.l10n.reviewTransfer,
                    isLoading: isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => unawaited(
                            _scheduleTransfer(context),
                          ),
                    icon: const Icon(Icons.event_repeat_rounded),
                    label: Text(context.l10n.scheduleTransfer),
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
