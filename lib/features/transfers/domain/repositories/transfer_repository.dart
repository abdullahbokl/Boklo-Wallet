import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';

abstract class TransferRepository {
  Future<Result<void>> createTransfer(TransferEntity transfer);
  Future<Result<List<TransferEntity>>> getTransfers();
  Stream<TransferStatus> observeTransferStatus(String transferId);
}
