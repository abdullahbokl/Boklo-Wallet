import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final TransactionEntity transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? Colors.green : Colors.red;
    final prefix = isCredit ? '+' : '-';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(
        isCredit ? 'Received' : 'Sent',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        DateFormat.yMMMd().add_jm().format(transaction.timestamp),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '$prefix \$${transaction.amount.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
