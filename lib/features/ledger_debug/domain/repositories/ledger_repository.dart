import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';

abstract class LedgerRepository {
  /// Stream of ledger entries for a specific wallet for real-time debugging.
  Stream<Result<List<LedgerEntryEntity>>> watchWalletLedger(
      {required String walletId});
}
