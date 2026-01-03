import 'dart:convert';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

abstract class WalletLocalDataSource {
  Future<void> cacheWallet(WalletModel wallet);
  Future<WalletModel?> getLastWallet();
  Future<void> cacheTransactions(List<TransactionModel> transactions);
  Future<List<TransactionModel>?> getLastTransactions();
}

@LazySingleton(as: WalletLocalDataSource)
class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  WalletLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const _walletKey = 'CACHED_WALLET';
  static const _transactionsKey = 'CACHED_TRANSACTIONS';

  @override
  Future<void> cacheWallet(WalletModel wallet) async {
    final jsonString = json.encode(wallet.toJson());
    await _storage.write(key: _walletKey, value: jsonString);
  }

  @override
  Future<WalletModel?> getLastWallet() async {
    final jsonString = await _storage.read(key: _walletKey);
    if (jsonString != null) {
      return WalletModel.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    }
    return null;
  }

  @override
  Future<void> cacheTransactions(List<TransactionModel> transactions) async {
    final jsonString = json.encode(
      transactions.map((e) => e.toJson()).toList(),
    );
    await _storage.write(key: _transactionsKey, value: jsonString);
  }

  @override
  Future<List<TransactionModel>?> getLastTransactions() async {
    final jsonString = await _storage.read(key: _transactionsKey);
    if (jsonString != null) {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return null;
  }
}
