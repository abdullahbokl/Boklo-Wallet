import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class TransferRepository {
  Future<Either<Failure, void>> createTransfer(TransferEntity transfer);
  Future<Either<Failure, List<TransferEntity>>> getTransfers();
  Future<Either<Failure, WalletEntity>> getWallet(String id);
  Stream<Either<Failure, TransferEntity?>> observeTransfer(String transferId);
}
