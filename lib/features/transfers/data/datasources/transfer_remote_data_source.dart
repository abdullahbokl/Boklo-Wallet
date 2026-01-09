import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

abstract class TransferRemoteDataSource {
  Future<void> createTransfer(TransferModel transfer);
  Future<List<TransferModel>> getTransfers();
  Future<WalletModel?> getWallet(String id);
  Future<WalletModel?> getWalletByAlias(String alias);
  Stream<TransferModel?> observeTransfer(String id);
}

@LazySingleton(as: TransferRemoteDataSource)
class TransferRemoteDataSourceImpl implements TransferRemoteDataSource {
  TransferRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> createTransfer(TransferModel transfer) async {
    final transferRef = _firestore.collection('transfers').doc(transfer.id);

    // BACKEND-AUTHORITY:
    // We strictly use a Firestore transaction here to ensure data consistency of the transfer record.
    // We DO NOT update wallet balances on the client.
    // The backend (Cloud Functions) is solely responsible for:
    // 1. Validating the transfer (again)
    // 2. Atomically updating balances (Ledger)
    // 3. Updating the transfer status to COMPLETED or FAILED
    await _firestore.runTransaction((transaction) async {
      // We read the doc first even though it's a new create, to ensure we don't overwrite if ID collides (rare but safe)
      final docSnapshot = await transaction.get(transferRef);
      if (docSnapshot.exists) {
        throw Exception('Transfer with ID ${transfer.id} already exists');
      }

      transaction.set(transferRef, transfer.toJson());
    });
  }

  @override
  Future<List<TransferModel>> getTransfers() async {
    // Implementation placeholder
    return [];
  }

  @override
  Future<WalletModel?> getWallet(String id) async {
    final doc = await _firestore.collection('wallets').doc(id).get();
    if (doc.exists) {
      return WalletModel.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Future<WalletModel?> getWalletByAlias(String alias) async {
    final query = await _firestore
        .collection('wallets')
        .where('alias', isEqualTo: alias)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return WalletModel.fromJson(query.docs.first.data());
    }
    return null;
  }

  @override
  Stream<TransferModel?> observeTransfer(String id) {
    return _firestore.collection('transfers').doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return TransferModel.fromJson(doc.data()!);
      }
      return null;
    });
  }
}
