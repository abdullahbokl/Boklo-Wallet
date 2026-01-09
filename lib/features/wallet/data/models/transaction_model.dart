import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final DateTime timestamp;

  final TransactionStatus status;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.timestamp,
    this.status = TransactionStatus.completed,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      type: entity.type,
      timestamp: entity.timestamp,
      status: entity.status,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      amount: amount,
      type: type,
      timestamp: timestamp,
      status: status,
    );
  }
}
