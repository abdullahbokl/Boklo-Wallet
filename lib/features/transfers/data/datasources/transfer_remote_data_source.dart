import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

abstract class TransferRemoteDataSource {
  Future<void> createTransfer(TransferModel transfer);
  Future<List<TransferModel>> getTransfers();
  Future<WalletModel?> getWallet(String id);
  Future<WalletModel?> getWalletByAlias(String alias);
}

@LazySingleton(as: TransferRemoteDataSource)
class TransferRemoteDataSourceImpl implements TransferRemoteDataSource {
  TransferRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> createTransfer(TransferModel transfer) async {
    final transferRef = _firestore.collection('transfers').doc(transfer.id);
    final fromWalletRef =
        _firestore.collection('wallets').doc(transfer.fromWalletId);
    final toWalletRef =
        _firestore.collection('wallets').doc(transfer.toWalletId);

    // Transaction Records for sender and receiver
    final fromTxRef =
        fromWalletRef.collection('transactions').doc('${transfer.id}_DEBIT');
    final toTxRef =
        toWalletRef.collection('transactions').doc('${transfer.id}_CREDIT');

    final timestamp = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final fromSnapshot = await transaction.get(fromWalletRef);
      final toSnapshot = await transaction.get(toWalletRef);

      if (!fromSnapshot.exists || !toSnapshot.exists) {
        throw Exception('Wallet not found');
      }

      final fromBalance = (fromSnapshot.data()?['balance'] as num).toDouble();
      final toBalance = (toSnapshot.data()?['balance'] as num).toDouble();

      if (fromBalance < transfer.amount) {
        throw Exception('Insufficient balance');
      }

      final fromTx = TransactionModel(
        id: fromTxRef.id,
        amount: transfer.amount,
        type: TransactionType.debit,
        timestamp: timestamp,
      );

      final toTx = TransactionModel(
        id: toTxRef.id,
        amount: transfer.amount,
        type: TransactionType.credit,
        timestamp: timestamp,
      );

      // Update everything in a single atomic commit.
      // 1. Deduct from sender wallet balance.
      // 2. Add Sender debit transaction record.
      // 3. Add to recipient wallet balance.
      // 4. Add Recipient credit transaction record.
      // 5. Create the main Transfer record.
      //
      // Using a transaction ensures that either all these operations succeed
      // or none of them do. This prevents money from being lost (deducted but
      // not added) or created out of thin air if an error occurs mid-process.
      transaction
        ..update(fromWalletRef, {'balance': fromBalance - transfer.amount})
        ..set(fromTxRef, fromTx.toJson())
        ..update(toWalletRef, {'balance': toBalance + transfer.amount})
        ..set(toTxRef, toTx.toJson())
        ..set(transferRef, transfer.toJson());
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
}
