import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_limits.dart';
import 'package:boklo/features/transfers/domain/usecases/get_transfer_limits_usecase.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_form.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({
    super.key,
    this.prefilledRecipient,
  });

  final String? prefilledRecipient;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TransferCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = getIt<WalletCubit>();
            unawaited(cubit.loadWallet());
            return cubit;
          },
        ),
      ],
      child: const _TransferScreen(),
    );
  }
}

class _TransferScreen extends StatelessWidget {
  const _TransferScreen();

  @override
  Widget build(BuildContext context) {
    final transferPage = context.findAncestorWidgetOfExactType<TransferPage>();
    return AppPageScaffold(
      title: context.l10n.sendMoney,
      child: Column(
        children: [
          Expanded(
            child: TransferForm(
              prefilledRecipient: transferPage?.prefilledRecipient,
            ),
          ),
          const TransferLimitsNote(),
        ],
      ),
    );
  }
}

/// Shows the caller's remaining daily limit (minor-units aware) under the
/// transfer form; silently hidden when the backend is unavailable.
class TransferLimitsNote extends StatefulWidget {
  const TransferLimitsNote({super.key});

  @override
  State<TransferLimitsNote> createState() => _TransferLimitsNoteState();
}

class _TransferLimitsNoteState extends State<TransferLimitsNote> {
  TransferLimits? _limits;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await getIt<GetTransferLimitsUseCase>()();
    if (!mounted) return;
    result.fold((_) {}, (limits) => setState(() => _limits = limits));
  }

  @override
  Widget build(BuildContext context) {
    final limits = _limits;
    if (limits == null) return const SizedBox.shrink();
    final currency = getIt<WalletCubit>().state.data?.wallet.currency ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.sm),
      child: Text(
        context.l10n.limitsRemaining(
          limits.remainingTodayMinor.moneyLabel(currency),
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
