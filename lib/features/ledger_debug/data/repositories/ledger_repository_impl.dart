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
  Stream<Result<List<LedgerEntryEntity>>> watchLedgerEntries() {
    // We listen to the global 'ledger' collection, which should work in DEV.
    // In strict production with security rules, this might be restricted, but this is DEV-ONLY.
    return _firestore
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
