import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/ledger_debug/data/models/ledger_entry_model.dart';
import 'package:boklo/features/ledger_debug/domain/entities/ledger_entry_entity.dart';
import 'package:boklo/features/ledger_debug/domain/repositories/ledger_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LedgerRepository)
class LedgerRepositoryImpl implements LedgerRepository {
  final FirebaseFirestore _firestore;

  LedgerRepositoryImpl(this._firestore);

  @override
  Stream<Result<List<LedgerEntryEntity>>> watchWalletLedger(
      {required String walletId}) {
    return _firestore
        .collection('wallets')
        .doc(walletId)
        .collection('ledger')
        .orderBy('occurredAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      try {
        final entries = snapshot.docs.map((doc) {
          return LedgerEntryModel.fromJson(doc.data(), doc.id).toEntity();
        }).toList();
        return Success(entries);
      } catch (e) {
        return Failure<List<LedgerEntryEntity>>(UnknownError(e.toString()));
      }
    });
  }
}
