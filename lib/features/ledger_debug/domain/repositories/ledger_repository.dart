import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';

abstract class LedgerRepository {
  /// Stream of ledger entries for a specific wallet for real-time debugging.
  Stream<Either<Failure, List<LedgerEntryEntity>>> watchWalletLedger(
      {required String walletId});
}
