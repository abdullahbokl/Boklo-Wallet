import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_item.dart';
import 'package:flutter/material.dart';

/// Renders a list of transactions fetched from the WalletRepository.
///
/// Data Flow:
/// 1. WalletCubit calls GetTransactionsUseCase.
/// 2. GetTransactionsUseCase calls WalletRepository.getTransactions.
/// 3. Repository fetches from Remote/Local data source.
/// 4. Data is emitted in WalletState and passed down here via WalletPage.
class TransactionList extends StatelessWidget {
  const TransactionList({
    required this.transactions,
    super.key,
    this.isLoading = false,
  });

  final List<TransactionEntity> transactions;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions yet',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionItem(transaction: transactions[index]);
      },
    );
  }
}
