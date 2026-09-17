import 'dart:async';

import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransferRepository)
class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(
    this._dataSource,
    this._validator,
  );

  final TransferRemoteDataSource _dataSource;
  final TransferValidator _validator;

  @override
  Future<Either<Failure, void>> createTransfer(TransferEntity transfer) async {
    try {
      final fromWalletModel = await _dataSource.getWallet(
        transfer.fromWalletId,
      );
      final toWalletModel = await _resolveWallet(transfer.toWalletId);

      if (fromWalletModel == null || toWalletModel == null) {
        return const Left(ValidationFailure('One or both wallets not found'));
      }

      final validation = _validator.validate(
        fromWallet: fromWalletModel.toEntity(),
        toWallet: toWalletModel.toEntity(),
        amount: transfer.amount,
      );

      return validation.fold(
        Left.new,
        (_) => _executeTransfer(transfer, toWalletModel.id),
      );
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Unknown error'));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> _executeTransfer(
    TransferEntity transfer,
    String resolvedRecipientId,
  ) async {
    try {
      final transferModel = TransferModel(
        id: transfer.id,
        fromWalletId: transfer.fromWalletId,
        toWalletId: resolvedRecipientId,
        amount: transfer.amount,
        currency: transfer.currency,
        status: TransferStatus.pending,
        createdAt: transfer.createdAt,
      );

      await _dataSource.createTransfer(transferModel);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Unknown error'));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransferEntity>>> getTransfers() async {
    try {
      final models = await _dataSource.getTransfers();
      return Right(models.map((e) => e.toEntity()).toList());
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, TransferEntity?>> observeTransfer(
    String transferId,
  ) async* {
    // Stream.handleError cannot emit values, so converting errors with it
    // silently kills the stream and the caller hangs until its timeout.
    // Mapping both event conversion and upstream stream errors into Left
    // values guarantees the cubit always receives a terminal result.
    try {
      await for (final data in _dataSource.observeTransfer(transferId)) {
        try {
          yield Right(data?.toEntity());
        } on Object catch (e) {
          yield Left(UnknownFailure(e.toString()));
        }
      }
    } on Object catch (e) {
      yield Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletEntity>> getWallet(String id) async {
    try {
      final model = await _resolveWallet(id);
      return model == null
          ? const Left(ValidationFailure('Wallet not found'))
          : Right(model.toEntity());
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<WalletModel?> _resolveWallet(String input) async {
    final cleaned = input.trim();
    if (cleaned.contains('@')) return _dataSource.getWalletByEmail(cleaned);
    if (cleaned.toUpperCase().startsWith('BOKLO-')) {
      return _dataSource.getWalletByAlias(cleaned.toUpperCase());
    }
    return _dataSource.getWallet(cleaned);
  }
}
