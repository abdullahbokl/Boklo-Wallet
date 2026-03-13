import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/status_chip.dart';
import 'package:flutter/material.dart';

/// A themed transaction tile with credit/debit styling and status badge.
///
/// Uses theme colors instead of hardcoded light-mode values
/// so it works correctly in both light and dark modes.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.isCredit,
    super.key,
    this.onTap,
  });

  final String title;
  final String amount;
  final String date;
  final TransactionStatus status;
  final bool isCredit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const successColor = Color(0xFF10B981);
    final errorColor = scheme.error;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.md),
          child: Row(
            children: [
              _TransactionIcon(isCredit: isCredit),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      date,
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}$amount',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCredit ? successColor : errorColor,
                    ),
                  ),
                  const SizedBox(height: AppDimens.xs4),
                  StatusChip(status: status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionIcon extends StatelessWidget {
  const _TransactionIcon({required this.isCredit});

  final bool isCredit;

  @override
  Widget build(BuildContext context) {
    final color = isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(AppDimens.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}
