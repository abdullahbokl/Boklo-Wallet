import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
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

      WalletModel? toWalletModel;
      if (transfer.toWalletId.toUpperCase().startsWith('BOKLO-')) {
        toWalletModel = await _dataSource
            .getWalletByAlias(transfer.toWalletId.toUpperCase());
      } else {
        toWalletModel = await _dataSource.getWallet(transfer.toWalletId);
      }

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
              toWalletId: toWalletModel!.id,
              amount: transfer.amount,
              currency: transfer.currency,
              status: TransferStatus.completed,
              createdAt: transfer.createdAt,
            );

            await _dataSource.createTransfer(transferModel);
            return const Success(null);
          } on FirebaseException catch (e) {
            return Failure(FirebaseError(e.message ?? 'Unknown error', e.code));
          } on Object catch (e) {
            return Failure(UnknownError(e.toString()));
          }
        },
      );
    } on Object catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<TransferEntity>>> getTransfers() async {
    try {
      final models = await _dataSource.getTransfers();
      return Success(models.map((e) => e.toEntity()).toList());
    } on Object catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}
