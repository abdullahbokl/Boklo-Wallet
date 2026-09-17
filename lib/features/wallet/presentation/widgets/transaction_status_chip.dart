import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/status_chip.dart';
import 'package:flutter/material.dart';

/// Maps the domain transaction status to a localized status chip.
class TransactionStatusChip extends StatelessWidget {
  const TransactionStatusChip({required this.status, super.key});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      TransactionStatus.pending => StatusChip(
        label: l10n.statusPending,
        color: AppColors.warning,
        icon: Icons.schedule_rounded,
      ),
      TransactionStatus.completed => StatusChip(
        label: l10n.statusCompleted,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      ),
      TransactionStatus.failed => StatusChip(
        label: l10n.statusFailed,
        color: AppColors.error,
        icon: Icons.error_rounded,
      ),
    };
  }
}
