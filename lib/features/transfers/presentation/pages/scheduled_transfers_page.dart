import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/domain/entities/scheduled_transfer_entity.dart';
import 'package:boklo/features/transfers/presentation/bloc/scheduled_transfers_cubit.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Lists the user's recurring transfers with cancel actions.
class ScheduledTransfersPage extends StatelessWidget {
  const ScheduledTransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.l10n.scheduledTitle,
      child: BlocProvider(
        create: (_) => getIt<ScheduledTransfersCubit>()..load(),
        child: const _ScheduledBody(),
      ),
    );
  }
}

class _ScheduledBody extends StatelessWidget {
  const _ScheduledBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ScheduledTransfersCubit,
      BaseState<List<ScheduledTransferEntity>>
    >(
      builder: (context, state) {
        if (state.isLoading) return const AppLoadingIndicator();
        final error = state.error;
        if (error != null) {
          return WalletErrorView(
            title: error.message,
            onRetry: () => context.read<ScheduledTransfersCubit>().load(),
          );
        }
        final schedules = state.data ?? const <ScheduledTransferEntity>[];

        if (schedules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.xxl),
              child: Text(
                context.l10n.scheduledEmpty,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: schedules.map((s) => _ScheduleCard(schedule: s)).toList(),
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final ScheduledTransferEntity schedule;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final frequencyLabel = switch (schedule.frequency) {
      ScheduleFrequency.daily => l10n.scheduledDaily,
      ScheduleFrequency.weekly => l10n.scheduledWeekly,
      ScheduleFrequency.monthly => l10n.scheduledMonthly,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        title: Text(
          schedule.amount.moneyLabel(schedule.currency),
          style: AppTypography.subtitle,
        ),
        subtitle: Text(
          '$frequencyLabel · ${DateFormat.yMMMd().format(schedule.nextRunAt)}',
          style: AppTypography.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          tooltip: l10n.scheduledCancel,
          icon: Icon(Icons.cancel_outlined, color: scheme.error),
          onPressed: () => unawaited(_confirmCancel(context)),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final scaffold = ScaffoldMessenger.of(context);
    final cubit = context.read<ScheduledTransfersCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scheduledCancel),
        content: Text(l10n.scheduledCancelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final ok = await cubit.cancel(schedule.id);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.scheduledCancelled : l10n.statementExportFailed,
        ),
      ),
    );
  }
}
