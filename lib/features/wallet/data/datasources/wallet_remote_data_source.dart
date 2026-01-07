import 'dart:math';

import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
}

@LazySingleton(as: WalletRemoteDataSource)
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._firestore, this._auth);

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
      final alias =
          'BOKLO-${Random().nextInt(9999).toString().padLeft(4, '0')}';
      final newWallet = WalletModel(
        id: userId,
        balance: 1000,
        currency: 'USD',
        alias: alias,
      );
      await docRef.set(newWallet.toJson());
      return newWallet;
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    // ... existing implementation
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final query = await _firestore
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    return query.docs
        .map((doc) => TransactionModel.fromJson(doc.data()))
        .toList();
  }
}
