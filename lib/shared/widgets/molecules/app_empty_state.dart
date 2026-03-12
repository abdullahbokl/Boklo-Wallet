import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                color: scheme.primaryContainer.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary, size: AppDimens.iconLg),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(color: scheme.onSurface),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimens.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimens.lg),
              AppButton(
                text: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.tonal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
