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
          title: const Text('Ledger Debug (Dev)'),
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<LedgerCubit, LedgerState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => Center(child: Text('Error: $message')),
              empty: () => _buildEmpty(),
              success: (entries, totalCredits, totalDebits, netDelta) {
                return Column(
                  children: [
                    _buildSummaryCard(totalCredits, totalDebits, netDelta),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: AppDimens.md),
          Text('No Ledger Entries Found', style: AppTypography.title),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double credits, double debits, double delta) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      _statItem('Total Credits', credits, AppColors.success)),
              Expanded(
                  child: _statItem('Total Debits', debits, AppColors.error)),
              Expanded(
                  child: _statItem('Net Delta', delta,
                      delta == 0 ? Colors.white : Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'System Integrity Check',
            style: AppTypography.caption.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: AppTypography.title.copyWith(color: color),
        ),
      ],
    );
  }
}
