import 'package:equatable/equatable.dart';

class LedgerEntryEntity extends Equatable {
  final String id;
  final String transactionId;
  final String walletId;
  final double amount;
  final String currency;
  final String direction; // 'DEBIT' or 'CREDIT'
  final DateTime occurredAt;
  final String? description;

  const LedgerEntryEntity({
    required this.id,
    required this.transactionId,
    required this.walletId,
    required this.amount,
    required this.currency,
    required this.direction,
    required this.occurredAt,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        transactionId,
        walletId,
        amount,
        currency,
        direction,
        occurredAt,
        description,
      ];
}
