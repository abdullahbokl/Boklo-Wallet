import 'dart:async';
import 'dart:developer';

import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

/// Result of a paginated transaction fetch.
class PaginatedTransactionResult {
  PaginatedTransactionResult({
    required this.transactions,
    required this.hasMore,
    this.lastDocument,
  });

  final List<TransactionModel> transactions;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
}

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
  Future<PaginatedTransactionResult> getTransactionsPaginated({
    DocumentSnapshot? startAfter,
    int limit = 20,
  });
  Stream<List<TransactionModel>> watchTransactions();
  Stream<WalletModel> watchWallet();
  Future<void> provisionWallet();
}

@LazySingleton(as: WalletRemoteDataSource)
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._firestore, this._auth, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  @override
  Stream<WalletModel> watchWallet() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(const ValidationError('User not logged in'));
    }

    return _firestore.collection('wallets').doc(userId).snapshots().transform(
            StreamTransformer<DocumentSnapshot<Map<String, dynamic>>,
                WalletModel>.fromHandlers(
          handleData: (doc, sink) {
            if (doc.exists && doc.data() != null) {
              try {
                sink.add(WalletModel.fromJson(doc.data()!));
              } catch (e) {
                // If deserialization fails, it's a real error
                sink.addError(ValidationError('Invalid wallet data: $e'));
              }
            } else {
              // Document does not exist yet (backend creation in progress).
              // We do NOT emit an error here. We stay silent.
              // The stream will stay active and emit when the backend creates the doc.
            }
          },
          handleError: (error, stack, sink) {
            sink.addError(UnknownError('Wallet stream error: $error'));
          },
        ));
  }

  @override
  Future<WalletModel> getWallet() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final docRef = _firestore.collection('wallets').doc(userId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return WalletModel.fromJson(doc.data()!);
    } else {
      // Backend is authoritative. If not found, it's a sync issue or delay.
      throw const ValidationError('Wallet not found (creation pending?)');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
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

  @override
  Future<PaginatedTransactionResult> getTransactionsPaginated({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    var query = _firestore
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data()))
        .toList();

    return PaginatedTransactionResult(
      transactions: transactions,
      hasMore: snapshot.docs.length == limit,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    );
  }

  @override
  Stream<List<TransactionModel>> watchTransactions() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(const ValidationError('User not logged in'));
    }

    return _firestore
        .collection('wallets')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (query) => query.docs
              .map((doc) => TransactionModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> provisionWallet() async {
    try {
      final callable = _functions.httpsCallable('provisionWallet');
      log('🔧 Calling provisionWallet function...');

      final result = await callable.call<Map<String, dynamic>>();
      final created = result.data['created'] as bool? ?? false;

      log('✅ provisionWallet ${created ? 'created new wallet' : 'wallet existed'}');
    } on FirebaseFunctionsException catch (e) {
      log('❌ provisionWallet failed: [${e.code}] ${e.message}');
      throw UnknownError('Failed to provision wallet: ${e.message}');
    } catch (e) {
      log('❌ provisionWallet unexpected error: $e');
      throw UnknownError('Failed to provision wallet: $e');
    }
  }
}
