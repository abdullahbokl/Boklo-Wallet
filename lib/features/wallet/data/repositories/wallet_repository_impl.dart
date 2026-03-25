import 'dart:async';
import 'dart:developer';

import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_local_data_source.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_page.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {

  WalletRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );
  final WalletRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _localDataSource;

  /// Cursor for pagination — stored here to keep domain layer
  /// free of Firestore-specific types.
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  @override
  Future<Either<Failure, WalletEntity>> getWallet() async {
    try {
      final remoteWallet = await _remoteDataSource.getWallet();
      await _localDataSource.cacheWallet(remoteWallet);
      return Right(remoteWallet.toEntity());
    } catch (e) {
      try {
        final localWallet = await _localDataSource.getLastWallet();
        if (localWallet != null) {
          return Right(localWallet.toEntity());
        }
      } catch (_) {}
      return Left(ServerFailure('Failed to fetch wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions() async {
    try {
      // Reset pagination cursor on fresh fetch
      _lastDocument = null;
      _hasMore = true;

      final result = await _remoteDataSource.getTransactionsPaginated();
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;

      try {
        await _localDataSource.cacheTransactions(result.transactions);
      } catch (e) {
        log('⚠️ Failed to cache transactions: $e');
      }

      return Right(
        result.transactions.map((e) => e.toEntity()).toList(),
      );
    } catch (e) {
      try {
        final localTransactions = await _localDataSource.getLastTransactions();
        if (localTransactions != null) {
          return Right(
            localTransactions.map((e) => e.toEntity()).toList(),
          );
        }
      } catch (_) {}
      return Left(ServerFailure('Failed to fetch transactions: $e'));
    }
  }

  @override
  Future<Either<Failure, TransactionPage>> loadMoreTransactions() async {
    if (!_hasMore) {
      return const Right(
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

      return Right(
        TransactionPage(transactions: entities, hasMore: _hasMore),
      );
    } catch (e) {
      return Left(ServerFailure('Failed to load more transactions: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions() {
    return _remoteDataSource.watchTransactions().transform(
          StreamTransformer<List<TransactionModel>,
              Either<Failure, List<TransactionEntity>>>.fromHandlers(
            handleData: (data, sink) {
              sink.add(Right(data.map((e) => e.toEntity()).toList()));
            },
            handleError: (error, stack, sink) {
              sink.add(Left(UnknownFailure('Stream error: $error')));
            },
          ),
        );
  }

  @override
  Stream<Either<Failure, WalletEntity>> watchWallet() {
    return _remoteDataSource.watchWallet().transform(
          StreamTransformer<WalletModel, Either<Failure, WalletEntity>>.fromHandlers(
            handleData: (data, sink) {
              sink.add(Right(data.toEntity()));
            },
            handleError: (error, stack, sink) {
              sink.add(Left(UnknownFailure('Stream error: $error')));
            },
          ),
        );
  }
}
