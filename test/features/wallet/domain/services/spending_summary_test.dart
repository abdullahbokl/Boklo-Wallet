import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/services/spending_summary.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  required TransactionType type,
  required int amount,
  required DateTime timestamp,
  TransactionStatus status = TransactionStatus.completed,
}) {
  return TransactionEntity(
    id: ['tx', type.name, amount].join('-'),
    amount: amount,
    type: type,
    timestamp: timestamp,
    status: status,
  );
}

void main() {
  group('SpendingSummaryCalculator', () {
    test('sums completed credits and debits within the month', () {
      final now = DateTime(2024, 3, 20);
      final summary = SpendingSummaryCalculator.currentMonth(
        now: now,
        transactions: [
          _tx(
            type: TransactionType.credit,
            amount: 100000,
            timestamp: DateTime(2024, 3, 5),
          ),
          _tx(
            type: TransactionType.debit,
            amount: 30000,
            timestamp: DateTime(2024, 3, 10),
          ),
          _tx(
            type: TransactionType.debit,
            amount: 20000,
            timestamp: DateTime(2024, 3, 12),
          ),
        ],
      );

      expect(summary.totalInMinor, 100000);
      expect(summary.totalOutMinor, 50000);
      expect(summary.transactionCount, 3);
      expect(summary.isEmpty, isFalse);
    });

    test('excludes other months and non-completed transactions', () {
      final now = DateTime(2024, 3, 20);
      final summary = SpendingSummaryCalculator.currentMonth(
        now: now,
        transactions: [
          _tx(
            type: TransactionType.credit,
            amount: 100000,
            timestamp: DateTime(2024, 2, 28),
          ),
          _tx(
            type: TransactionType.credit,
            amount: 100000,
            timestamp: DateTime.parse('2024-04-01'),
          ),
          _tx(
            type: TransactionType.credit,
            amount: 100000,
            timestamp: DateTime(2024, 3, 10),
            status: TransactionStatus.pending,
          ),
          _tx(
            type: TransactionType.debit,
            amount: 100000,
            timestamp: DateTime(2024, 3, 10),
            status: TransactionStatus.failed,
          ),
        ],
      );

      expect(summary.totalInMinor, 0);
      expect(summary.totalOutMinor, 0);
      expect(summary.isEmpty, isTrue);
    });

    test('window boundaries: start inclusive, end exclusive', () {
      final summary = SpendingSummaryCalculator.forWindow(
        start: DateTime.parse('2024-03-01'),
        end: DateTime.parse('2024-04-01'),
        transactions: [
          _tx(
            type: TransactionType.credit,
            amount: 100,
            timestamp: DateTime.parse('2024-03-01'),
          ),
          _tx(
            type: TransactionType.credit,
            amount: 100,
            timestamp: DateTime.parse('2024-04-01'),
          ),
        ],
      );

      expect(summary.totalInMinor, 100);
    });
  });
}
