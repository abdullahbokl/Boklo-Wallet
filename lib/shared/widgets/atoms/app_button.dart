import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, tonal, destructive }

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
    this.variant,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double? height;
  final AppButtonVariant? variant;

  @override
  Widget build(BuildContext context) {
    final effectiveVariant =
        variant ?? (isSecondary ? AppButtonVariant.secondary : AppButtonVariant.primary);
    final enabled = onPressed != null && !isLoading;
    final scheme = Theme.of(context).colorScheme;

    final config = switch (effectiveVariant) {
      AppButtonVariant.primary => _ButtonConfig(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          borderColor: scheme.primary,
        ),
      AppButtonVariant.secondary => _ButtonConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: scheme.onSurface,
          borderColor: scheme.outlineVariant,
        ),
      AppButtonVariant.tonal => _ButtonConfig(
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.75),
          foregroundColor: scheme.primary,
          borderColor: Colors.transparent,
        ),
      AppButtonVariant.destructive => _ButtonConfig(
          backgroundColor: AppColors.error,
          foregroundColor: scheme.onError,
          borderColor: AppColors.error,
        ),
    };

    return SizedBox(
      width: width,
      height: height ?? AppDimens.buttonHeight,
      child: Material(
        color: enabled
            ? config.backgroundColor
            : scheme.onSurface.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          side: BorderSide(
            color: enabled
                ? config.borderColor
                : scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
            child: Center(
              child: _ButtonContent(
                button: this,
                color: enabled
                    ? config.foregroundColor
                    : scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonConfig {
  const _ButtonConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.button,
    required this.color,
  });

  final AppButton button;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (button.isLoading) {
      return AppLoadingIndicator(
        center: false,
        size: 18,
        strokeWidth: 2,
        color: color,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (button.icon != null) ...[
          Icon(button.icon, size: AppDimens.iconMd, color: color),
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
