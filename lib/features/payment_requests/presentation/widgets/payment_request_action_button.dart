import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:flutter/material.dart';

class PaymentRequestActionButton extends StatelessWidget {
  const PaymentRequestActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: isPrimary ? 0.3 : 0.1),
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                AppLoadingIndicator(
                  center: false,
                  size: 16,
                  strokeWidth: 2,
                  color: color,
                )
              else ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppDimens.xs),
                Text(
                  label,
                  style: AppTypography.label.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
