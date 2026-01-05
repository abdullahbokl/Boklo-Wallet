import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
}

@LazySingleton(as: WalletRemoteDataSource)
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._firestore, this._auth) {
    print(
        'WalletRemoteDataSourceImpl initialized with user: ${_auth.currentUser?.uid}');
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<WalletModel> getWallet() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final docRef = _firestore.collection('wallets').doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      return WalletModel.fromJson(doc.data()!);
    } else {
      // Create a default wallet for new users
      final newWallet = WalletModel(
        id: userId,
        balance: 1000.0, // Starting balance bonus
        currency: 'USD',
      );
      await docRef.set(newWallet.toJson());
      return newWallet;
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    // Query transfers where user is sender OR receiver
    // Note: Firestore requires separate queries or an 'OR' query (available in newer SDKs)
    // For simplicity, we'll fetch 'sent' and 'received' separately and merge.

    final sentQuery = await _firestore
        .collection('transfers')
        .where('fromWalletId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final receivedQuery = await _firestore
        .collection('transfers')
        .where('toWalletId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final sent = sentQuery.docs.map((doc) {
      final data = doc.data();
      return TransactionModel(
        id: doc.id,
        amount: (data['amount'] as num).toDouble(),
        type: TransactionType.debit,
        timestamp: (data['createdAt'] as Timestamp).toDate(),
      );
    });

    final received = receivedQuery.docs.map((doc) {
      final data = doc.data();
      return TransactionModel(
        id: doc.id,
        amount: (data['amount'] as num).toDouble(),
        type: TransactionType.credit,
        timestamp: (data['createdAt'] as Timestamp).toDate(),
      );
    });

    final all = [...sent, ...received]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }
}
