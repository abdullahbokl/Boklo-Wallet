import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';

abstract class TransferRepository {
  Future<Result<void>> createTransfer(TransferEntity transfer);
  Future<Result<List<TransferEntity>>> getTransfers();
  Future<Result<WalletEntity>> getWallet(String id);
  Stream<TransferEntity?> observeTransfer(String transferId);
}
