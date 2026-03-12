import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/features/wallet/presentation/widgets/quick_actions_row.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_filters.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_list.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
import 'package:boklo/shared/widgets/molecules/balance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletContent extends StatelessWidget {
  const WalletContent({
    required this.data,
    super.key,
  });

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppDimens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 380),
                  tween: Tween(begin: 0.96, end: 1),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: BalanceCard(
                    balance: data.wallet.balance,
                    currency: data.wallet.currency,
                    walletId: data.wallet.id,
                    username: data.wallet.username,
                    alias: data.wallet.alias,
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                QuickActionsRow(
                  onSendTap: () {
                    unawaited(getIt<NavigationService>().push('/transfer'));
                  },
                  onPaymentRequestsTap: () {
                    unawaited(getIt<NavigationService>().push('/payment-requests'));
                  },
                  onContactsTap: () {
                    unawaited(getIt<NavigationService>().push('/contacts'));
                  },
                  onNotificationsTap: () {
                    unawaited(getIt<NavigationService>().push('/notification-settings'));
                  },
                ),
                const SizedBox(height: AppDimens.sectionGap),
                AppSectionHeader(
                  title: 'Recent activity',
                  subtitle: 'Track completed and pending money movement.',
                  trailing: TextButton(
                    onPressed: data.filterType != null || data.filterStatus != null
                        ? () => context.read<WalletCubit>().clearFilters()
                        : null,
                    child: const Text('Clear filters'),
                  ),
                ),
                const SizedBox(height: AppDimens.sm),
                TransactionFilters(data: data),
                const SizedBox(height: AppDimens.md),
              ],
            ),
          ),
        ),
        TransactionList(
          transactions: data.transactions,
          hasMore: data.hasMore,
          isLoadingMore: data.isLoadingMore,
          onLoadMore: () {
            context.read<WalletCubit>().loadMoreTransactions();
          },
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppDimens.xl),
        ),
      ],
    );
  }
}
