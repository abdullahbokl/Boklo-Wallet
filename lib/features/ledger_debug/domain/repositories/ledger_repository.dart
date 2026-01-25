import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';

abstract class LedgerRepository {
  /// Stream of ledger entries for real-time debugging.
  /// Depending on architecture, this could be global or per-wallet.
  /// For debug purposes, we might want to see global if admin, or wallet-specific.
  /// Given "Dev-Only", we might default to global or allow filtering.
  Stream<Result<List<LedgerEntryEntity>>> watchLedgerEntries();
}
