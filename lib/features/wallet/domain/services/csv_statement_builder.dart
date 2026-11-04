import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:intl/intl.dart';

/// Builds RFC-4180-compliant CSV statements from transactions.
///
/// Amounts are rendered in major units (minor/100) with a currency column;
/// all fields are quoted and escaped so descriptions containing commas,
/// quotes, or newlines survive round-trips into spreadsheet apps.
class CsvStatementBuilder {
  const CsvStatementBuilder._();

  static const List<String> _headers = [
    'Date',
    'Type',
    'Status',
    'Amount',
    'Currency',
    'Counterparty',
    'Description',
    'Transaction ID',
  ];

  /// Builds a full CSV document. [currency] applies to every row.
  static String build({
    required List<TransactionEntity> transactions,
    required String currency,
  }) {
    final buffer = StringBuffer()..writeln(_encodeRow(_headers));

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final rows = [...transactions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final tx in rows) {
      buffer.writeln(
        _encodeRow([
          dateFormat.format(tx.timestamp.toUtc()),
          tx.type.name,
          tx.status.name,
          (tx.amount / 100).toStringAsFixed(2),
          currency,
          tx.counterpartyId ?? '',
          tx.description ?? '',
          tx.id,
        ]),
      );
    }
    return buffer.toString();
  }

  /// RFC 4180: wrap in double quotes, double any embedded quotes.
  static String _encodeField(String field) {
    if (field.contains('"') ||
        field.contains(',') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _encodeRow(List<String> fields) =>
      fields.map(_encodeField).join(',');
}
