import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/wallet/domain/services/spending_summary.dart';
import 'package:boklo/features/wallet/domain/usecases/export_statement_usecase.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
import 'package:flutter/material.dart';

/// "This month" in/out summary card + statement export entry point.
///
/// Loads the full history once in the background; failures collapse the
/// card silently (insights are non-critical).
class SpendingInsightsCard extends StatefulWidget {
  const SpendingInsightsCard({required this.currency, super.key});

  final String currency;

  @override
  State<SpendingInsightsCard> createState() => _SpendingInsightsCardState();
}

class _SpendingInsightsCardState extends State<SpendingInsightsCard> {
  SpendingSummary? _summary;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await getIt<GetAllTransactionsUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) {},
      (transactions) {
        setState(() {
          _summary = SpendingSummaryCalculator.currentMonth(
            transactions: transactions,
          );
        });
      },
    );
  }

  Future<void> _exportStatement() async {
    if (_exporting) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);

    final result = await getIt<ExportStatementUseCase>()(
      currency: widget.currency,
    );
    if (!mounted) return;
    setState(() => _exporting = false);

    result.fold(
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.statementExportFailed)),
      ),
      (_) => messenger.showSnackBar(
        SnackBar(content: Text(l10n.statementShared)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: context.l10n.insightsThisMonth,
          subtitle: context.l10n.statementExportHint,
          trailing: IconButton(
            tooltip: context.l10n.statementExport,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            onPressed: _exporting ? null : () => unawaited(_exportStatement()),
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: summary == null || summary.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Text(
                          context.l10n.insightsNoActivity,
                          style: AppTypography.bodyMedium.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _SummaryColumn(
                          icon: Icons.south_west_rounded,
                          label: context.l10n.insightsMoneyIn,
                          amountMinor: summary.totalInMinor,
                          currency: widget.currency,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: VerticalDivider(
                          width: AppDimens.xl,
                          color: scheme.outlineVariant,
                        ),
                      ),
                      Expanded(
                        child: _SummaryColumn(
                          icon: Icons.north_east_rounded,
                          label: context.l10n.insightsMoneyOut,
                          amountMinor: summary.totalOutMinor,
                          currency: widget.currency,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.icon,
    required this.label,
    required this.amountMinor,
    required this.currency,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amountMinor;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppDimens.xs4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.xs4),
        Text(
          amountMinor.moneyLabel(currency),
          style: AppTypography.subtitle.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}
