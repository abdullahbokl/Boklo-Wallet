import 'dart:async';

import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/shared/widgets/atoms/app_shimmer.dart';
import 'package:boklo/shared/widgets/molecules/balance_card_badge.dart';
import 'package:flutter/foundation.dart';
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

  final double balance;
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

    return GestureDetector(
      onTap: () {
        if (kDebugMode || kProfileMode) {
          unawaited(getIt<NavigationService>().push('/ledger-debug'));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.xl),
        decoration: AppDecorations.gradientCard(),
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
                      'Available balance',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: AppDimens.xs4),
                    Text(
                      'Funds ready to send or request',
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
                    balance.toStringAsFixed(2),
                    style: AppTypography.amount.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.sm,
                vertical: AppDimens.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Text(
                kDebugMode ? 'Debug tap opens ledger view' : 'Protected wallet balance',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ),
          ],
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
