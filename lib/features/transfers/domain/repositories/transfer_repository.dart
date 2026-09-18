import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_limits.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class TransferRepository {
  Future<Either<Failure, void>> createTransfer(TransferEntity transfer);
  Future<Either<Failure, WalletEntity>> getWallet(String id);
  Future<Either<Failure, TransferLimits>> getTransferLimits();
  Future<Either<Failure, WalletEntity>> getPublicWallet(String id);
  Stream<Either<Failure, TransferEntity?>> observeTransfer(String transferId);
}
