import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';

/// Represents a paginated page of transactions.
///
/// [transactions] is the list of transactions for this page.
/// [hasMore] indicates whether more pages are available.
class TransactionPage {
  const TransactionPage({
    required this.transactions,
    required this.hasMore,
  });

  final List<TransactionEntity> transactions;
  final bool hasMore;
}
