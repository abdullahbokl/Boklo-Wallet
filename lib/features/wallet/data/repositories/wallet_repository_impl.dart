import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_local_data_source.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _localDataSource;

  WalletRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<Result<WalletEntity>> getWallet() async {
    try {
      // 1. Try to get latest from remote
      final remoteWallet = await _remoteDataSource.getWallet();
      // 2. Cache it
      await _localDataSource.cacheWallet(remoteWallet);
      // 3. Return it
      return Success(remoteWallet.toEntity());
    } catch (e) {
      // 4. Fallback to local
      try {
        final localWallet = await _localDataSource.getLastWallet();
        if (localWallet != null) {
          return Success(localWallet.toEntity());
        }
      } catch (_) {
        // Ignore local read errors
      }
      return Failure(UnknownError('Failed to fetch wallet: $e'));
    }
  }

  @override
  Future<Result<List<TransactionEntity>>> getTransactions() async {
    try {
      final remoteTransactions = await _remoteDataSource.getTransactions();
      await _localDataSource.cacheTransactions(remoteTransactions);
      return Success(
        remoteTransactions.map((e) => e.toEntity()).toList(),
      );
    } catch (e) {
      try {
        final localTransactions = await _localDataSource.getLastTransactions();
        if (localTransactions != null) {
          return Success(
            localTransactions.map((e) => e.toEntity()).toList(),
          );
        }
      } catch (_) {
        // Ignore local read errors
      }
      return Failure(UnknownError('Failed to fetch transactions: $e'));
    }
  }

  @override
  Stream<Result<List<TransactionEntity>>> watchTransactions() {
    return _remoteDataSource.watchTransactions().transform(
          StreamTransformer<List<TransactionModel>,
              Result<List<TransactionEntity>>>.fromHandlers(
            handleData: (data, sink) {
              sink.add(Success(data.map((e) => e.toEntity()).toList()));
            },
            handleError: (error, stack, sink) {
              sink.add(Failure(UnknownError('Stream error: $error')));
            },
          ),
        );
  }
}
