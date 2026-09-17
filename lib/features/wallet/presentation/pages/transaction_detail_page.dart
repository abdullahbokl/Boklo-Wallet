import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/dispute_repository.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_status_chip.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Detail view for a single transaction. Reached by tapping a tile in the
/// wallet history. Route extra: `{transaction, currency, walletId}`.
class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({
    required this.transaction,
    required this.currency,
    required this.walletId,
    super.key,
  });

  /// Parses the route extra passed by [GoRouter].
  factory TransactionDetailPage.fromExtra(Map<String, dynamic> extra) {
    return TransactionDetailPage(
      transaction: extra['transaction']! as TransactionEntity,
      currency: extra['currency']! as String,
      walletId: extra['walletId']! as String,
    );
  }

  final TransactionEntity transaction;
  final String currency;
  final String walletId;

  static const routePath = '/transaction-detail';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isCredit = transaction.type == TransactionType.credit;
    final dateFormat = DateFormat.yMMMd().add_jm();

    return AppPageScaffold(
      title: l10n.transactionDetailTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.lg),
          Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 40,
            color: isCredit ? Colors.green : scheme.error,
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            (isCredit ? '+' : '-') + transaction.amount.moneyLabel(currency),
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppDimens.sm),
          Center(
            child: TransactionStatusChip(status: transaction.status),
          ),
          const SizedBox(height: AppDimens.xl),
          _Row(
            label: l10n.detailDate,
            value: dateFormat.format(transaction.timestamp),
          ),
          if (transaction.counterpartyId != null)
            _CopyableRow(
              label: isCredit ? l10n.detailFrom : l10n.detailTo,
              value: transaction.counterpartyId!,
            ),
          if (transaction.description != null &&
              transaction.description!.isNotEmpty)
            _Row(
              label: l10n.detailDescription,
              value: transaction.description!,
            ),
          _CopyableRow(label: l10n.detailTransactionId, value: transaction.id),
          const Spacer(),
          if (transaction.status == TransactionStatus.failed)
            AppButton(
              text: l10n.tryAgain,
              onPressed: () {
                final recipient = transaction.counterpartyId;
                if (recipient != null) {
                  unawaited(context.push('/transfer', extra: recipient));
                }
              },
            ),
          const SizedBox(height: AppDimens.md),
          AppButton(
            text: l10n.reportProblem,
            variant: AppButtonVariant.secondary,
            onPressed: () => unawaited(_reportProblem(context)),
          ),
          const SizedBox(height: AppDimens.lg),
        ],
      ),
    );
  }

  Future<void> _reportProblem(BuildContext context) async {
    final l10n = context.l10n;
    final snackbar = getIt<SnackbarService>();
    final reasonController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reportProblem),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.reportProblemHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.reportProblemSubmit),
          ),
        ],
      ),
    );

    if (submitted != true) return;

    final result = await getIt<DisputeRepository>().submitDispute(
      transactionId: transaction.id,
      walletId: walletId,
      amount: transaction.amount,
      currency: currency,
      reason: reasonController.text.trim(),
    );
    result.fold(
      (failure) => snackbar.showError(failure.message),
      (_) => snackbar.showSuccess(l10n.reportProblemSubmitted),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.trailing});

  final String label;
  final String value;
  final Widget? trailing;

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
          ?trailing,
        ],
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      value: value,
      trailing: IconButton(
        icon: const Icon(Icons.copy_rounded, size: 18),
        tooltip: context.l10n.copiedToClipboard,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: value));
          if (context.mounted) {
            getIt<SnackbarService>().showSuccess(
              context.l10n.copiedToClipboard,
            );
          }
        },
      ),
    );
  }
}
