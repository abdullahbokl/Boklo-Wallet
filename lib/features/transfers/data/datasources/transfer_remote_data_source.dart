import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

abstract class TransferRemoteDataSource {
  Future<void> createTransfer(TransferModel transfer);
  Future<List<TransferModel>> getTransfers();
  Future<WalletModel?> getWallet(String id);
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

      transaction
        ..update(fromWalletRef, {'balance': fromBalance - transfer.amount})
        ..update(toWalletRef, {'balance': toBalance + transfer.amount})
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
}
