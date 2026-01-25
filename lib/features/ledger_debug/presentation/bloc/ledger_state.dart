import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ledger_state.freezed.dart';

@freezed
class LedgerState with _$LedgerState {
  const factory LedgerState.initial() = _Initial;
  const factory LedgerState.loading() = _Loading;
  const factory LedgerState.success({
    required List<LedgerEntryEntity> entries,
    required double totalCredits,
    required double totalDebits,
    required double netDelta,
  }) = _Success;
  const factory LedgerState.empty() = _Empty;
  const factory LedgerState.error(String message) = _Error;
}
