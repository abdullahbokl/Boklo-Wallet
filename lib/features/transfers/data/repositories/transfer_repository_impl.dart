import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<Result<void>> createTransfer(TransferEntity transfer) async {
    try {
      final fromWalletModel =
          await _dataSource.getWallet(transfer.fromWalletId);

      // Unified Resolution for recipient
      final toWalletModel = await _resolveWallet(transfer.toWalletId);

      if (fromWalletModel == null || toWalletModel == null) {
        return const Failure(ValidationError('One or both wallets not found'));
      }

      final validationResult = _validator.validate(
        fromWallet: fromWalletModel.toEntity(),
        toWallet: toWalletModel.toEntity(),
        amount: transfer.amount,
      );

      return validationResult.fold(
        Failure.new,
        (_) async {
          try {
            // Use the resolved recipient ID
            final transferModel = TransferModel(
              id: transfer.id,
              fromWalletId: transfer.fromWalletId,
              toWalletId: toWalletModel.id,
              amount: transfer.amount,
              currency: transfer.currency,
              status: TransferStatus.pending,
              createdAt: transfer.createdAt,
            );

            await _dataSource.createTransfer(transferModel);
            return const Success(null);
          } on FirebaseException catch (e) {
            return Failure(FirebaseError(e.message ?? 'Unknown error', e.code));
          } on Object catch (e) {
            return Failure(UnknownError('Failed to create transfer', e));
          }
        },
      );
    } on FirebaseException catch (e) {
      return Failure(FirebaseError(e.message ?? 'Unknown error', e.code));
    } on Object catch (e) {
      return Failure(UnknownError('An unexpected error occurred', e));
    }
  }

  @override
  Future<Result<List<TransferEntity>>> getTransfers() async {
    try {
      final models = await _dataSource.getTransfers();
      return Success(models.map((e) => e.toEntity()).toList());
    } on Object catch (e) {
      return Failure(UnknownError('Failed to load transfers', e));
    }
  }

  @override
  Stream<TransferEntity?> observeTransfer(String transferId) {
    return _dataSource.observeTransfer(transferId).map((model) {
      return model?.toEntity();
    });
  }

  @override
  Future<Result<WalletEntity>> getWallet(String id) async {
    try {
      final model = await _resolveWallet(id);
      if (model == null) {
        return const Failure(ValidationError('Wallet not found'));
      }
      return Success(model.toEntity());
    } on Object catch (e) {
      return Failure(UnknownError('Failed to get wallet', e));
    }
  }

  /// Unified Wallet Resolution Logic
  /// 1. Email
  /// 2. Alias
  /// 3. ID
  Future<WalletModel?> _resolveWallet(String input) async {
    final cleanedInput = input.trim();

    // 1. Email Resolution
    if (cleanedInput.contains('@')) {
      return _dataSource.getWalletByEmail(cleanedInput);
    }

    // 2. Alias Resolution
    if (cleanedInput.toUpperCase().startsWith('BOKLO-')) {
      return _dataSource.getWalletByAlias(cleanedInput.toUpperCase());
    }

    // 3. ID Resolution (Default)
    return _dataSource.getWallet(cleanedInput);
  }
}
