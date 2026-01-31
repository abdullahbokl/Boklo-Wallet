import 'dart:async';

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/features/wallet/presentation/widgets/quick_actions_row.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_list.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_primary_action.dart';
import 'package:boklo/shared/presentation/widgets/dev_info_widget.dart';
import 'package:boklo/shared/widgets/molecules/balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletContent extends StatelessWidget {
  const WalletContent({required this.data, super.key});

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    // Attempt to get user ID from AuthCubit for debug info
    final user = context.read<AuthCubit>().state.maybeWhen(
          success: (u) => u,
          orElse: () => null,
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dev Info (Auto-hidden in release)
          DevInfoWidget(
            userId: user?.id,
            walletId: data.wallet.id,
          ),
          const SizedBox(height: AppDimens.sm),

          // Entrance Animation for Balance Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.9, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: BalanceCard(
              balance: data.wallet.balance,
              currency: data.wallet.currency,
              walletId: data.wallet.id,
              username: data.wallet.username,
              alias: data.wallet.alias,
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          // Quick Actions
          WalletPrimaryAction(
            onSendMoney: () async {
              unawaited(getIt<NavigationService>().push('/transfer'));
            },
          ),
          const SizedBox(height: AppDimens.md),
          QuickActionsRow(
            onPaymentRequestsTap: () {
              unawaited(getIt<NavigationService>().push('/payment-requests'));
            },
            onContactsTap: () {
              unawaited(getIt<NavigationService>().push('/contacts'));
            },
            onNotificationsTap: () {
              unawaited(
                getIt<NavigationService>().push('/notification-settings'),
              );
            },
          ),
          const SizedBox(height: AppDimens.xl),
          Text(
            'Recent Transactions',
            style:
                AppTypography.title.copyWith(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: AppDimens.md),
          _TransactionFilters(data: data),
          const SizedBox(height: AppDimens.md),
          TransactionList(transactions: data.transactions),
        ],
      ),
    );
  }
}

class _TransactionFilters extends StatelessWidget {
  const _TransactionFilters({required this.data});

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: data.filterType == null,
            onSelected: (bool selected) {
              context.read<WalletCubit>().setFilterType(null);
            },
          ),
          const SizedBox(width: AppDimens.sm),
          FilterChip(
            label: const Text('Income'),
            selected: data.filterType == TransactionType.credit,
            onSelected: (bool selected) {
              context.read<WalletCubit>().setFilterType(
                    selected ? TransactionType.credit : null,
                  );
            },
          ),
          const SizedBox(width: AppDimens.sm),
          FilterChip(
            label: const Text('Expense'),
            selected: data.filterType == TransactionType.debit,
            onSelected: (bool selected) {
              context.read<WalletCubit>().setFilterType(
                    selected ? TransactionType.debit : null,
                  );
            },
          ),
        ],
      ),
    );
  }
}
