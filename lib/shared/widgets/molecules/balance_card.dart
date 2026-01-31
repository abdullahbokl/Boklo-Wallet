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

  /// Gets the display ID in priority order: username > alias > walletId
  String? get _displayId {
    if (username != null && username!.isNotEmpty) {
      return '@$username';
    }
    if (alias != null && alias!.isNotEmpty) {
      return alias;
    }
    if (walletId != null && walletId!.isNotEmpty) {
      // Truncate long wallet IDs
      return walletId!.length > 8
          ? '${walletId!.substring(0, 8)}...'
          : walletId;
    }
    return null;
  }

  /// Gets the value to copy to clipboard (full username without @, or full walletId)
  String? get _copyValue {
    if (username != null && username!.isNotEmpty) {
      return username;
    }
    if (alias != null && alias!.isNotEmpty) {
      return alias;
    }
    return walletId;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        height: 180, // Approximate height of the card
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        // DEV-ONLY: Secret debug menu entry
        if (kDebugMode) {
          unawaited(getIt<NavigationService>().push('/ledger-debug'));
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
                if (_displayId != null)
                  InkWell(
                    onTap: () {
                      if (_copyValue != null) {
                        unawaited(
                          Clipboard.setData(ClipboardData(text: _copyValue!)),
                        );
                        getIt<SnackbarService>()
                            .showInfo('Copied to clipboard');
                      }
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
                            _displayId!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
