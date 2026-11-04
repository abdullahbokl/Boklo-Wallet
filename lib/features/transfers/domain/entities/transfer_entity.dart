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
    required this.amount, // integer minor units
    required this.currency,
    required this.status,
    required this.createdAt,
    this.failureReason,
    this.errorCode,
    this.reasons,
    this.riskLevel,
    this.riskMode,
  });

  final String id;
  final String fromWalletId;
  final String toWalletId;
  final int amount;
  final String currency;
  final TransferStatus status;
  final DateTime createdAt;
  final String? failureReason;

  /// Machine-readable failure code (e.g. INSUFFICIENT_BALANCE) emitted by the
  /// backend so clients can localize failure text.
  final String? errorCode;
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
    errorCode,
    reasons,
    riskLevel,
    riskMode,
  ];
}
