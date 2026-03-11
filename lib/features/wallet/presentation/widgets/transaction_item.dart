import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({required this.transaction, super.key});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final colorScheme = Theme.of(context).colorScheme;

    // UI Polish: Colors and Icons
    final statusColor = _getStatusColor(context);
    final icon =
        isCredit ? Icons.south_west_rounded : Icons.north_east_rounded;
    final label = isCredit ? 'Received' : 'Sent';
    final prefix = isCredit ? '+' : '-';
    final amountColor = isCredit ? Colors.green : colorScheme.onSurface;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        vertical: AppDimens.xs4,
        horizontal: AppDimens.md,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(AppDimens.xs),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: AppDimens.iconMd,
            ),
          ),
          const SizedBox(width: AppDimens.md),
          
          // Transaction Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormat.MMMd().add_jm().format(transaction.timestamp),
                      style: AppTypography.caption.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (transaction.status != TransactionStatus.completed) ...[
                      const SizedBox(width: AppDimens.xs),
                      _buildStatusBadge(context),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$prefix\$${transaction.amount.toStringAsFixed(2)}',
                style: AppTypography.subtitle.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'USD',
                style: AppTypography.overline.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (transaction.type == TransactionType.credit) return Colors.green;
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isFailed = transaction.status == TransactionStatus.failed;
    final color = isFailed ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Text(
        isFailed ? 'FAILED' : 'PENDING',
        style: AppTypography.overline.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
