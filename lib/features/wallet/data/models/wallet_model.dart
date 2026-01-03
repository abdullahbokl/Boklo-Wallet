import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  final String id;
  final double balance;
  final String currency;

  const WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) =>
      _$WalletModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletModelToJson(this);

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      balance: entity.balance,
      currency: entity.currency,
    );
  }

  WalletEntity toEntity() {
    return WalletEntity(
      id: id,
      balance: balance,
      currency: currency,
    );
  }
}
