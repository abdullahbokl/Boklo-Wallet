import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/services/csv_statement_builder.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  required String id,
  required TransactionType type,
  required int amount,
  TransactionStatus status = TransactionStatus.completed,
  DateTime? timestamp,
  String? description,
}) {
  return TransactionEntity(
    id: id,
    amount: amount,
    type: type,
    timestamp: timestamp ?? DateTime(2024, 3, 15, 12, 30),
    status: status,
    counterpartyId: 'counterparty-1',
    description: description,
  );
}

void main() {
  group('CsvStatementBuilder', () {
    test('emits headers then rows, newest first', () {
      final csv = CsvStatementBuilder.build(
        transactions: [
          _tx(id: 'old', type: TransactionType.debit, amount: 1000),
          _tx(
            id: 'new',
            type: TransactionType.credit,
            amount: 250000,
            timestamp: DateTime.parse('2024-04-01'),
          ),
        ],
        currency: 'EGP',
      );

      final lines = csv.trim().split('\n');
      expect(lines.first, contains('Date,Type,Status,Amount'));
      expect(lines[1], contains('new'));
      expect(lines[2], contains('old'));
      expect(csv, contains('2500.00'));
      expect(csv, contains('EGP'));
      expect(csv, contains('debit'));
      expect(csv, contains('completed'));
    });

    test('escapes commas, quotes and newlines in descriptions', () {
      final csv = CsvStatementBuilder.build(
        transactions: [
          _tx(
            id: 't1',
            type: TransactionType.debit,
            amount: 500,
            description: 'Rent, "April"\nline2',
          ),
        ],
        currency: 'EGP',
      );

      expect(
        csv,
        contains('"Rent, ""April""\nline2"'),
      );
    });

    test('renders minor units with two decimals', () {
      final csv = CsvStatementBuilder.build(
        transactions: [
          _tx(id: 't1', type: TransactionType.credit, amount: 5),
          _tx(id: 't2', type: TransactionType.credit, amount: 105050),
        ],
        currency: 'EGP',
      );

      expect(csv, contains('0.05'));
      expect(csv, contains('1050.50'));
    });
  });
}
