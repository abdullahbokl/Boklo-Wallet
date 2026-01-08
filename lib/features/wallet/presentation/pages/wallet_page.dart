import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_list.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_balance_card.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_primary_action.dart';
import 'package:boklo/shared/responsive/responsive_builder.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: BlocBuilder<WalletCubit, BaseState<WalletState>>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error) => Center(child: Text(error.message)),
            success: (data) => ResponsiveBuilder(
              mobile: (context, _) => _WalletLayout(data: data),
              tablet: (context, _) => Center(
                child: SizedBox(
                  width: 600,
                  child: _WalletLayout(data: data),
                ),
              ),
              desktop: (context, _) => Center(
                child: SizedBox(
                  width: 800,
                  child: _WalletLayout(data: data),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletLayout extends StatelessWidget {
  const _WalletLayout({required this.data});

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WalletBalanceCard(wallet: data.wallet),
          WalletPrimaryAction(
            onSendMoney: () async {
              final navigationService = getIt<NavigationService>();
              // result is expected to be boolean true
              // if transfer was successful
              final result = await navigationService.push<bool>('/transfer');

              if ((result ?? false) && context.mounted) {
                // Trigger refresh on the provided WalletCubit
                unawaited(context.read<WalletCubit>().loadWallet());
              }
            },
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.m),
          TransactionList(transactions: data.transactions),
        ],
      ),
    );
  }
}
