import 'package:boklo/core/network/retry_executor.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

abstract class TransferRemoteDataSource {
  Future<void> createTransfer(TransferModel transfer);

  /// Reads the caller's OWN wallet document (full data, owner-only rules).
  Future<WalletModel?> getWallet(String id);

  /// Reads another user's wallet data from the balance-free public
  /// collection (the only wallet data other users may see).
  Future<WalletModel?> getPublicWallet(String id);

  /// Resolves an alias to a public wallet record.
  Future<WalletModel?> getWalletByAlias(String alias);

  /// Resolves an email to a public wallet record (exact lookup only).
  Future<WalletModel?> getWalletByEmail(String email);

  /// Resolves a username to a public wallet record.
  Future<WalletModel?> getWalletByUsername(String username);

  Stream<TransferModel?> observeTransfer(String id);
}

@LazySingleton(as: TransferRemoteDataSource)
class TransferRemoteDataSourceImpl implements TransferRemoteDataSource {
  TransferRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> createTransfer(TransferModel transfer) async {
    // Retry with exponential backoff for transient network errors.
    // Business errors (duplicate ID) will NOT be retried.
    await RetryExecutor.run(() async {
      final transferRef = _firestore.collection('transfers').doc(transfer.id);

      // BACKEND-AUTHORITY:
      // We strictly use a Firestore transaction here to ensure data
      // consistency of the transfer record.
      // We DO NOT update wallet balances on the client.
      // The backend (Cloud Functions) is solely responsible for:
      // 1. Validating the transfer (again)
      // 2. Atomically updating balances (Ledger)
      // 3. Updating the transfer status to COMPLETED or FAILED
      await _firestore.runTransaction((transaction) async {
        // Read the doc first even though it's a new create, to ensure we
        // don't overwrite if the ID collides (rare but safe).
        final docSnapshot = await transaction.get(transferRef);
        if (docSnapshot.exists) {
          throw Exception('Transfer with ID ${transfer.id} already exists');
        }

        transaction.set(transferRef, transfer.toJson());
      });
    });
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
  Future<WalletModel?> getPublicWallet(String id) async {
    final doc = await _firestore.collection('wallet_public').doc(id).get();
    if (doc.exists) {
      return WalletModel.fromPublicMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<WalletModel?> getWalletByAlias(String alias) async {
    final query = await _firestore
        .collection('wallet_public')
        .where('alias', isEqualTo: alias)
        .limit(2)
        .get();

    if (query.docs.length > 1) {
      throw Exception(
        'Data integrity error: Multiple wallets found with alias $alias',
      );
    }

    if (query.docs.isNotEmpty) {
      return WalletModel.fromPublicMap(query.docs.first.data());
    }
    return null;
  }

  @override
  Future<WalletModel?> getWalletByEmail(String email) async {
    // Exact identifier lookup (list queries are denied by rules, so the
    // user directory cannot be harvested).
    final mappingDoc = await _firestore
        .collection('wallet_identifiers')
        .doc('email:${email.toLowerCase()}')
        .get();

    final walletId = mappingDoc.data()?['walletId'] as String?;
    if (walletId == null) {
      return null;
    }

    return getPublicWallet(walletId);
  }

  @override
  Future<WalletModel?> getWalletByUsername(String username) async {
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();

    if (!usernameDoc.exists) {
      return null;
    }

    final uid = usernameDoc.data()?['uid'] as String?;
    if (uid == null) {
      return null;
    }

    return getPublicWallet(uid);
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
