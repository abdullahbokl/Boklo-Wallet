import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:boklo/shared/widgets/atoms/app_shimmer.dart';
import 'package:boklo/shared/widgets/molecules/balance_card_badge.dart';
import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.balance,
    required this.currency,
    this.walletId,
    this.username,
    this.alias,
    this.isLoading = false,
    super.key,
  });

  /// Integer minor units.
  final int balance;
  final String currency;
  final String? walletId;
  final String? username;
  final String? alias;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeleton();
    }

    return DecoratedBox(
      decoration: AppDecorations.gradientCard(),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        // We use a SizedBox(width: double.infinity) to replace Container's
        // width
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.availableBalance,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                        ),
                      ),
                      const SizedBox(height: AppDimens.xs4),
                      Text(
                        context.l10n.fundsReadyToSendOrRequest,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.64),
                        ),
                      ),
                    ],
                  ),
                  BalanceCardBadge(
                    username: username,
                    alias: alias,
                    walletId: walletId,
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency,
                    style: AppTypography.amountSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(width: AppDimens.xs),
                  Expanded(
                    child: Text(
                      balance.moneyLabel(currency),
                      style: AppTypography.amount.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return AppShimmer(
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
      ),
    );
  }
}
