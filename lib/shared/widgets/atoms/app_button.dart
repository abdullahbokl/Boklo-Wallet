import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// A premium, standardized button with gradient support.
///
/// Primary style: gradient background with white text.
/// Secondary style: flat text button with primary color text.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (isSecondary) return _SecondaryButton(button: this);
    return _PrimaryButton(button: this);
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.button});
  final AppButton button;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = button.onPressed != null && !button.isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: enabled ? AppColors.shadowSm : null,
        color: enabled ? null : scheme.onSurface.withValues(alpha: 0.12),
      ),
      child: SizedBox(
        width: button.width,
        height: button.height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            onTap: enabled ? button.onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.md,
                horizontal: AppDimens.lg,
              ),
              child: Center(
                child: _ButtonContent(button: button, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.button});
  final AppButton button;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: button.width,
      height: button.height,
      child: TextButton(
        onPressed: button.isLoading ? null : button.onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.md,
            horizontal: AppDimens.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
        ),
        child: _ButtonContent(button: button, color: scheme.primary),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.button, required this.color});
  final AppButton button;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (button.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (button.icon != null) ...[
          Icon(button.icon, size: 20, color: color),
          const SizedBox(width: AppDimens.xs),
        ],
        Text(
          button.text,
          style: AppTypography.label.copyWith(color: color),
        ),
      ],
    );
  }
}
