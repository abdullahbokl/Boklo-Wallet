import 'package:boklo/core/utils/json_converters.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transfer_model.g.dart';

@JsonSerializable()
class TransferModel {
  const TransferModel({
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

  factory TransferModel.fromJson(Map<String, dynamic> json) =>
      _$TransferModelFromJson(json);

  factory TransferModel.fromEntity(TransferEntity entity) {
    return TransferModel(
      id: entity.id,
      fromWalletId: entity.fromWalletId,
      toWalletId: entity.toWalletId,
      amount: entity.amount,
      currency: entity.currency,
      status: entity.status,
      createdAt: entity.createdAt,
      failureReason: entity.failureReason,
      reasons: entity.reasons,
      riskLevel: entity.riskLevel,
      riskMode: entity.riskMode,
    );
  }

  final String id;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String currency;
  final TransferStatus status;
  @TimestampConverter()
  final DateTime createdAt;
  final String? failureReason;
  final List<String>? reasons;
  final String? riskLevel;
  final String? riskMode;

  Map<String, dynamic> toJson() => _$TransferModelToJson(this);

  TransferEntity toEntity() {
    return TransferEntity(
      id: id,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      currency: currency,
      status: status,
      createdAt: createdAt,
      failureReason: failureReason,
      reasons: reasons,
      riskLevel: riskLevel,
      riskMode: riskMode,
    );
  }
}
