import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_entity.freezed.dart';

@freezed
class WalletEntity with _$WalletEntity {
  const factory WalletEntity({
    required String id,
    required double balance,
    required String currency,
    String? alias,
  }) = _WalletEntity;
}
