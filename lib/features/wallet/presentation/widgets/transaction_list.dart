import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart'
    as domain;
import 'package:boklo/shared/widgets/atoms/status_chip.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:boklo/shared/widgets/molecules/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({
    required this.transactions,
    super.key,
    this.isLoading = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final List<domain.TransactionEntity> transactions;
  final bool isLoading;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (transactions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppEmptyState(
          icon: Icons.receipt_long_rounded,
          title: 'No transactions yet',
          subtitle: 'Your income and expenses will appear here.',
        ),
      );
    }

    // Total item count: transactions + optional load more row
    final showLoadMore = hasMore || isLoadingMore;
    final itemCount = transactions.length + (showLoadMore ? 1 : 0);

    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Load More button at the end
        if (index == transactions.length) {
          return _LoadMoreButton(
            isLoading: isLoadingMore,
            onPressed: onLoadMore,
          );
        }

        final tx = transactions[index];
        final isCredit = tx.type == domain.TransactionType.credit;

        // Map Domain Status to UI Status
        var uiStatus = TransactionStatus.pending;
        switch (tx.status) {
          case domain.TransactionStatus.pending:
            uiStatus = TransactionStatus.pending;
          case domain.TransactionStatus.completed:
            uiStatus = TransactionStatus.completed;
          case domain.TransactionStatus.failed:
            uiStatus = TransactionStatus.failed;
        }

        return TransactionTile(
          title: isCredit ? 'Received Money' : 'Sent Money',
          amount: tx.amount.toStringAsFixed(2),
          date: DateFormat.yMMMd().add_jm().format(tx.timestamp),
          status: uiStatus,
          isCredit: isCredit,
        );
      },
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({
    required this.isLoading,
    this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
      child: Center(
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Load More'),
              ),
      ),
    );
  }
}
