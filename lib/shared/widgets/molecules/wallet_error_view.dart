import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

class WalletErrorView extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;

  const WalletErrorView({
    super.key,
    this.title = 'Failed to load wallet',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_off,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            title,
            style: AppTypography.title.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppDimens.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              foregroundColor: AppColors.error,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
