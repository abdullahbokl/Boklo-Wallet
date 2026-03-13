import 'dart:async';

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/ledger_debug/presentation/bloc/ledger_cubit.dart';
import 'package:boklo/features/ledger_debug/presentation/bloc/ledger_state.dart';
import 'package:boklo/features/ledger_debug/presentation/widgets/ledger_entry_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LedgerDebugPage extends StatelessWidget {
  const LedgerDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<LedgerCubit>();
        unawaited(cubit.startWatching());
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ledger'),
        ),
        body: BlocBuilder<LedgerCubit, LedgerState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => Center(child: Text('Error: $message')),
              empty: () => _buildEmpty(context),
              success: (entries, totalCredits, totalDebits, netDelta) {
                return Column(
                  children: [
                    _buildSummaryCard(
                        context, totalCredits, totalDebits, netDelta,),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppDimens.md),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          return LedgerEntryTile(entry: entries[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64, color: scheme.onSurfaceVariant,),
          const SizedBox(height: AppDimens.md),
          Text('No transactions yet', style: AppTypography.title),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, double credits, double debits, double delta,) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      color: scheme.surfaceContainer,
      child: Row(
        children: [
          Expanded(
              child: _statItem(context, 'Credits', credits, AppColors.success),),
          Expanded(
              child: _statItem(context, 'Debits', debits, AppColors.error),),
          Expanded(
              child: _statItem(
                  context,
                  'Net',
                  delta,
                  delta == 0
                      ? scheme.onSurface
                      : (delta > 0 ? AppColors.success : AppColors.error),),),
        ],
      ),
    );
  }

  Widget _statItem(
      BuildContext context, String label, double value, Color color,) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label,
            style:
                AppTypography.caption.copyWith(color: scheme.onSurfaceVariant),),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: AppTypography.title.copyWith(color: color),
        ),
      ],
    );
  }
}

