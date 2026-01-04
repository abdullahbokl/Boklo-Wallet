import 'package:equatable/equatable.dart';

enum TransferStatus {
  pending,
  completed,
  failed,
}

class TransferEntity extends Equatable {
  const TransferEntity({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String currency;
  final TransferStatus status;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        fromWalletId,
        toWalletId,
        amount,
        currency,
        status,
        createdAt,
      ];
}
