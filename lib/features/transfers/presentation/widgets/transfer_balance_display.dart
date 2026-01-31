import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

class TransferBalanceDisplay extends StatelessWidget {
  const TransferBalanceDisplay({required this.wallet, super.key});

  final WalletEntity wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Text(
            'Available Balance',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            '${wallet.currency} ${wallet.balance.toStringAsFixed(2)}',
            style: AppTypography.headline.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
