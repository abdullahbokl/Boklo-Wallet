import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/shared/widgets/molecules/balance_card.dart' show BalanceCard;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Small badge shown on [BalanceCard] displaying the wallet owner's ID.
///
/// Shows username > alias > truncated walletId in priority order.
/// Tapping copies the ID to clipboard.
class BalanceCardBadge extends StatelessWidget {
  const BalanceCardBadge({
    super.key,
    this.username,
    this.alias,
    this.walletId,
  });

  final String? username;
  final String? alias;
  final String? walletId;

  String? get _displayId {
    if (username != null && username!.isNotEmpty) return '@$username';
    if (alias != null && alias!.isNotEmpty) return alias;
    if (walletId != null && walletId!.isNotEmpty) {
      return walletId!.length > 8
          ? '${walletId!.substring(0, 8)}...'
          : walletId;
    }
    return null;
  }

  String? get _copyValue {
    if (username != null && username!.isNotEmpty) return username;
    if (alias != null && alias!.isNotEmpty) return alias;
    return walletId;
  }

  @override
  Widget build(BuildContext context) {
    if (_displayId == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        if (_copyValue != null) {
          unawaited(Clipboard.setData(ClipboardData(text: _copyValue!)));
          getIt<SnackbarService>().showInfo('Copied to clipboard');
        }
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.sm,
          vertical: AppDimens.xs4,
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
              ),
            ),
            const SizedBox(width: AppDimens.xs4),
            const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
