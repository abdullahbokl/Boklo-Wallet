import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({required this.transaction, super.key});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;

    // UI Polish: Colors and Icons
    final color = isCredit ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor = isCredit ? Colors.green.shade50 : Colors.red.shade50;
    final icon =
        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final label = isCredit ? 'Received' : 'Sent';
    final prefix = isCredit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.s,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s + 4,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(transaction.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '$prefix ${transaction.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
