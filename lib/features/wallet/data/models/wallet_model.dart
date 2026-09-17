import 'package:boklo/core/utils/json_converters.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  const WalletModel({
    required this.id,
    required this.balance,
    required this.currency,
    this.username,
    this.ownerName,
    this.alias,
    this.email,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) =>
      _$WalletModelFromJson(json);

  /// Maps a `wallet_public` document (balance-free, discovery-safe).
  /// Balance is deliberately 0 here; validators must only use identity,
  /// currency, and liveness fields from public documents.
  factory WalletModel.fromPublicMap(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String? ?? '',
      balance: 0,
      currency: json['currency'] as String? ?? 'EGP',
      username: json['username'] as String?,
      ownerName: json['ownerName'] as String?,
      alias: json['alias'] as String?,
    );
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      balance: entity.balance,
      currency: entity.currency,
      username: entity.username,
      ownerName: entity.ownerName,
      alias: entity.alias,
      email: entity.email,
    );
  }
  final String id;
  @MinorUnitsConverter()
  final int balance;
  final String currency;
  final String? username;
  final String? ownerName;
  final String? alias;
  final String? email;

  Map<String, dynamic> toJson() => _$WalletModelToJson(this);

  WalletEntity toEntity() {
    return WalletEntity(
      id: id,
      balance: balance,
      currency: currency,
      username: username,
      ownerName: ownerName,
      alias: alias,
      email: email,
    );
  }
}
