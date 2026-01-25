import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({required this.entry, super.key});

  final LedgerEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final isCredit = entry.direction == 'CREDIT';
    final color = isCredit ? AppColors.success : AppColors.error;
    final prefix = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border:
            Border.all(color: AppColors.textSecondaryLight.withOpacity(0.1)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TX: ${entry.transactionId.substring(0, 8)}...',
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.direction,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: entry.walletId));
                      getIt<SnackbarService>()
                          .showSuccess('Wallet ID copied to clipboard');
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: Row(
                      children: [
                        Text(
                          'Wallet: ...${entry.walletId.substring(entry.walletId.length - 6)}',
                          style:
                              AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm:ss.SSS').format(entry.occurredAt),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              Text(
                '$prefix ${entry.amount.toStringAsFixed(2)} ${entry.currency}',
                style: AppTypography.title.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
