import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

class SummaryItem extends StatelessWidget {
  const SummaryItem({
    required this.label,
    required this.value,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          value,
          style: isPrimary ? AppTypography.title : AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
