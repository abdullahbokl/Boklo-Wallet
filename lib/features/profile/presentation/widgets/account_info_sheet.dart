import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:flutter/material.dart';

/// Read-only view of the details linked to the account (email, username,
/// display name). Profile editing is intentionally not offered — identity
/// fields are backend-managed.
class AccountInfoSheet extends StatelessWidget {
  const AccountInfoSheet({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.personalInformation,
              style: AppTypography.title,
            ),
            const SizedBox(height: AppDimens.lg),
            _InfoRow(label: context.l10n.email, value: user.email),
            if (user.username != null && user.username!.isNotEmpty)
              _InfoRow(
                label: context.l10n.username,
                value: '@${user.username}',
              ),
            if (user.displayName != null && user.displayName!.isNotEmpty)
              _InfoRow(
                label: context.l10n.displayNameOptional,
                value: user.displayName!,
              ),
            _InfoRow(
              label: context.l10n.verifyEmailTitle,
              value: user.emailVerified
                  ? context.l10n.statusCompleted
                  : context.l10n.statusPending,
            ),
            const SizedBox(height: AppDimens.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: context.l10n.receiptDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Divider(height: 1, color: scheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.xs4),
          Text(value, style: AppTypography.bodyLarge),
        ],
      ),
    );
  }
}
