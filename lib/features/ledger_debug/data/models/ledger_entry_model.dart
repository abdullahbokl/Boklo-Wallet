import 'package:boklo/core/utils/json_converters.dart';
import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerEntryModel {
  const LedgerEntryModel({
    required this.id,
    required this.transactionId,
    required this.walletId,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.occurredAt,
    this.description,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json, String id) {
    return LedgerEntryModel(
      id: id,
      transactionId: json['transactionId'] as String? ?? 'unknown_tx',
      walletId: json['walletId'] as String? ?? 'unknown_wallet',
      // Start with robust parsing for amount
      amount: () {
        final val = json['amount'];
        if (val is num) return val.round();
        if (val is String) return int.tryParse(val) ?? 0;
        return 0;
      }(),
      currency: json['currency'] as String? ?? 'USD',
      direction: json['direction'] as String? ?? 'UNKNOWN',
      occurredAt: () {
        final val = json['occurredAt'];
        if (val is Timestamp) return val.toDate();
        if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
        return DateTime.now();
      }(),
      description: json['description'] as String?,
    );
  }
  final String id;
  final String transactionId;
  final String walletId;
  @MinorUnitsConverter()
  final int amount;
  final String currency;
  final String direction;
  final DateTime occurredAt;
  final String? description;

  LedgerEntryEntity toEntity() {
    return LedgerEntryEntity(
      id: id,
      transactionId: transactionId,
      walletId: walletId,
      amount: amount,
      currency: currency,
      direction: direction,
      occurredAt: occurredAt,
      description: description,
    );
  }
}
