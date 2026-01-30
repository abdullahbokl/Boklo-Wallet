import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimens.dart';
import '../../../../config/theme/app_typography.dart';

/// A premium, standardized button with gradient support.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.md,
            horizontal: AppDimens.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        child: _buildContent(context),
      );
    }

    // Gradient Button for Primary
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppColors.primaryGradient : null,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: onPressed != null ? AppColors.shadowSm : null,
        color: onPressed == null
            ? AppColors.textSecondaryLight.withOpacity(0.2)
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Transparent to show gradient
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.md,
            horizontal: AppDimens.lg,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isSecondary ? AppColors.primary : Colors.white,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: AppDimens.xs),
        ],
        Text(
          text,
          style: isSecondary
              ? AppTypography.label.copyWith(color: AppColors.primary)
              : AppTypography.label, // Inherits white from toggleColor
        ),
      ],
    );
  }
}
