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
    this.failureReason,
    this.reasons,
    this.riskLevel,
    this.riskMode,
  });

  final String id;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String currency;
  final TransferStatus status;
  final DateTime createdAt;
  final String? failureReason;
  final List<String>? reasons;
  final String? riskLevel;
  final String? riskMode;

  @override
  List<Object?> get props => [
        id,
        fromWalletId,
        toWalletId,
        amount,
        currency,
        status,
        createdAt,
        failureReason,
        reasons,
        riskLevel,
        riskMode,
      ];
}
