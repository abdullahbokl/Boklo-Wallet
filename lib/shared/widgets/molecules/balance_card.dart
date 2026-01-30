import 'dart:async'; // For unawaited
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.balance,
    required this.currency,
    this.walletId,
    this.alias,
    super.key,
  });

  final double balance;
  final String currency;
  final String? walletId;
  final String? alias;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // DEV-ONLY: Secret debug menu entry
        if (kDebugMode) {
          getIt<NavigationService>().push('/ledger-debug');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          boxShadow: AppColors.shadowLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                if (alias != null || walletId != null)
                  InkWell(
                    onTap: () {
                      unawaited(
                        Clipboard.setData(
                            ClipboardData(text: alias ?? walletId!)),
                      );
                      getIt<SnackbarService>()
                          .showInfo('Wallet ID copied to clipboard');
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.sm,
                        vertical: AppDimens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alias != null
                                ? 'ID: $alias'
                                : 'ID: ${walletId!.length > 8 ? '${walletId!.substring(0, 8)}...' : walletId}',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontFamily: 'Monospace',
                            ),
                          ),
                          const SizedBox(width: AppDimens.xs),
                          const Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.xs),
            Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
