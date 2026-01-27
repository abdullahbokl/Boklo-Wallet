import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_state.freezed.dart';

@freezed
class WalletState with _$WalletState {
  const factory WalletState({
    required WalletEntity wallet,
    @Default([]) List<TransactionEntity> transactions,
    TransactionType? filterType,
    TransactionStatus? filterStatus,
  }) = _WalletState;
}
