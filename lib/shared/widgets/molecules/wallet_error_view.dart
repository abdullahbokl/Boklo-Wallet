import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

class WalletErrorView extends StatelessWidget {
  const WalletErrorView({
    required this.onRetry,
    super.key,
    this.title = 'Unable to load this section',
  });

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppDimens.xl),
        decoration: AppDecorations.mutedPanel(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.signal_wifi_off_rounded,
                color: scheme.error,
                size: AppDimens.iconLg,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppDimens.xs),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            AppButton(
              text: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              variant: AppButtonVariant.tonal,
            ),
          ],
        ),
      ),
    );
  }
}
