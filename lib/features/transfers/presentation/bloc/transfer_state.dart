import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_state.freezed.dart';

@freezed
abstract class TransferState with _$TransferState {
  const factory TransferState({
    /// Set once the backend confirms the transfer reached the terminal
    /// [TransferStatus.completed] state.
    TransferEntity? completedTransfer,
  }) = _TransferState;
}
