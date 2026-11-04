import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';

/// Aggregated money movement for a period, in integer minor units.
class SpendingSummary {
  const SpendingSummary({
    required this.totalInMinor,
    required this.totalOutMinor,
    required this.transactionCount,
    required this.periodStart,
    required this.periodEnd,
  });

  final int totalInMinor;
  final int totalOutMinor;
  final int transactionCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  bool get isEmpty => transactionCount == 0;
}

/// Computes spending summaries from completed transactions.
class SpendingSummaryCalculator {
  const SpendingSummaryCalculator._();

  /// Calendar-month window containing [reference].
  static DateTime monthStart(DateTime reference) =>
      DateTime(reference.year, reference.month);

  /// Sums completed credits/debits of [transactions] that fall inside the
  /// [start] (inclusive) / [end] (exclusive) window. Pending and failed
  /// transactions never count toward a summary.
  static SpendingSummary forWindow({
    required List<TransactionEntity> transactions,
    required DateTime start,
    required DateTime end,
  }) {
    var totalIn = 0;
    var totalOut = 0;
    var count = 0;

    for (final tx in transactions) {
      if (tx.status != TransactionStatus.completed) continue;
      if (tx.timestamp.isBefore(start) || !tx.timestamp.isBefore(end)) {
        continue;
      }
      count++;
      switch (tx.type) {
        case TransactionType.credit:
          totalIn += tx.amount;
        case TransactionType.debit:
          totalOut += tx.amount;
      }
    }

    return SpendingSummary(
      totalInMinor: totalIn,
      totalOutMinor: totalOut,
      transactionCount: count,
      periodStart: start,
      periodEnd: end,
    );
  }

  /// Current calendar month (as of [now]).
  static SpendingSummary currentMonth({
    required List<TransactionEntity> transactions,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final start = monthStart(reference);
    final end = DateTime(reference.year, reference.month + 1);
    return forWindow(transactions: transactions, start: start, end: end);
  }
}
