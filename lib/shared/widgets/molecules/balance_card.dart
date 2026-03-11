import 'dart:async';

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/shared/widgets/molecules/balance_card_badge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays the wallet balance with gradient styling and owner info badge.
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
    if (isLoading) return _buildSkeleton();

    return GestureDetector(
      onTap: () {
        if (kDebugMode || kProfileMode) {
          unawaited(getIt<NavigationService>().push('/ledger-debug'));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: AppDecorations.gradientCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppDimens.sm),
            _buildBalance(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Balance',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        BalanceCardBadge(
          username: username,
          alias: alias,
          walletId: walletId,
        ),
      ],
    );
  }

  Widget _buildBalance() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          currency,
          style: AppTypography.headline.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: AppDimens.xs),
        Text(
          balance.toStringAsFixed(2),
          style: AppTypography.display.copyWith(
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.shimmerBaseLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
    );
  }
}
