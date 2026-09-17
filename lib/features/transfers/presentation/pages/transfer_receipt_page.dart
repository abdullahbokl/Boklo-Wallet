import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Post-payment receipt: confirms a completed transfer with shareable
/// proof. Route extra: the completed [TransferEntity].
class TransferReceiptPage extends StatelessWidget {
  const TransferReceiptPage({required this.transfer, super.key});

  final TransferEntity transfer;

  static const routePath = '/transfer-receipt';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMMMd().add_jm();

    return AppPageScaffold(
      title: l10n.receiptTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.xl),
          Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: scheme.primary,
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            transfer.amount.moneyLabel(transfer.currency),
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(fontSize: 32),
          ),
          const SizedBox(height: AppDimens.xl),
          _Row(l10n.receiptRecipient, transfer.toWalletId),
          _Row(
            l10n.detailDate,
            dateFormat.format(transfer.createdAt),
          ),
          _Row(l10n.detailTransactionId, transfer.id),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.share_rounded),
            label: Text(l10n.receiptShare),
            onPressed: () {
              final text = l10n.receiptShareText(
                transfer.amount.moneyLabel(transfer.currency),
                dateFormat.format(transfer.createdAt),
                transfer.id,
              );
              unawaited(SharePlus.instance.share(ShareParams(text: text)));
            },
          ),
          const SizedBox(height: AppDimens.sm),
          AppButton(
            text: l10n.receiptDone,
            onPressed: () => context.go('/wallet'),
          ),
          const SizedBox(height: AppDimens.lg),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
