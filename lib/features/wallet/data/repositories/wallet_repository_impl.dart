import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_local_data_source.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_page.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _localDataSource;

  /// Cursor for pagination — stored here to keep domain layer
  /// free of Firestore-specific types.
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  WalletRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  @override
  Future<Result<WalletEntity>> getWallet() async {
    try {
      final remoteWallet = await _remoteDataSource.getWallet();
      await _localDataSource.cacheWallet(remoteWallet);
      return Success(remoteWallet.toEntity());
    } catch (e) {
      try {
        final localWallet = await _localDataSource.getLastWallet();
        if (localWallet != null) {
          return Success(localWallet.toEntity());
        }
      } catch (_) {}
      return Failure(UnknownError('Failed to fetch wallet: $e'));
    }
  }

  @override
  Future<Result<List<TransactionEntity>>> getTransactions() async {
    try {
      // Reset pagination cursor on fresh fetch
      _lastDocument = null;
      _hasMore = true;

      final result = await _remoteDataSource.getTransactionsPaginated();
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;

      await _localDataSource.cacheTransactions(result.transactions);
      return Success(
        result.transactions.map((e) => e.toEntity()).toList(),
      );
    } catch (e) {
      try {
        final localTransactions = await _localDataSource.getLastTransactions();
        if (localTransactions != null) {
          return Success(
            localTransactions.map((e) => e.toEntity()).toList(),
          );
        }
      } catch (_) {}
      return Failure(UnknownError('Failed to fetch transactions: $e'));
    }
  }

  @override
  Future<Result<TransactionPage>> loadMoreTransactions() async {
    if (!_hasMore) {
      return const Success(
        TransactionPage(transactions: [], hasMore: false),
      );
    }

    try {
      final result = await _remoteDataSource.getTransactionsPaginated(
        startAfter: _lastDocument,
      );
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;

      final entities = result.transactions.map((e) => e.toEntity()).toList();

      return Success(
        TransactionPage(transactions: entities, hasMore: _hasMore),
      );
    } catch (e) {
      return Failure(UnknownError('Failed to load more transactions: $e'));
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

  @override
  Stream<Result<WalletEntity>> watchWallet() {
    return _remoteDataSource.watchWallet().transform(
          StreamTransformer<WalletModel, Result<WalletEntity>>.fromHandlers(
            handleData: (data, sink) {
              sink.add(Success(data.toEntity()));
            },
            handleError: (error, stack, sink) {
              sink.add(Failure(UnknownError('Stream error: $error')));
            },
          ),
        );
  }
}
