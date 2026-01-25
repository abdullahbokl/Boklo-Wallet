import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart'
    as domain;
import 'package:boklo/shared/widgets/molecules/transaction_tile.dart'; // NEW
import 'package:boklo/shared/widgets/atoms/status_chip.dart'; // NEW Enum mapping
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    required this.transactions,
    super.key,
    this.isLoading = false,
  });

  final List<domain.TransactionEntity> transactions;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xl),
          child: Text(
            'No transactions yet',
            style: AppTypography.bodyLarge.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx.type == domain.TransactionType.credit;

        // Map Domain Status to UI Status
        TransactionStatus uiStatus = TransactionStatus.pending;
        switch (tx.status) {
          case domain.TransactionStatus.pending:
            uiStatus = TransactionStatus.pending;
            break;
          case domain.TransactionStatus.completed:
            uiStatus = TransactionStatus.completed;
            break;
          case domain.TransactionStatus.failed:
            uiStatus = TransactionStatus.failed;
            break;
        }

        return TransactionTile(
          title: isCredit ? 'Received Money' : 'Sent Money',
          amount: '${tx.amount.toStringAsFixed(2)}',
          date: DateFormat.yMMMd().add_jm().format(tx.timestamp),
          status: uiStatus,
          isCredit: isCredit,
        );
      },
    );
  }
}
