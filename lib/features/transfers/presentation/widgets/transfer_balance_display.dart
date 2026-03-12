import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';

class TransferBalanceDisplay extends StatelessWidget {
  const TransferBalanceDisplay({
    required this.wallet,
    super.key,
  });

  final WalletEntity wallet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                wallet.currency,
                style: AppTypography.amountSmall.copyWith(
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppDimens.xs),
              Expanded(
                child: Text(
                  wallet.balance.toStringAsFixed(2),
                  style: AppTypography.amount.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
