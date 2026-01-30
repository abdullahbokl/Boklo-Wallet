import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ObserveTransferStatusUseCase {
  ObserveTransferStatusUseCase(this.repository);

  final TransferRepository repository;

  Stream<TransferEntity?> call(String transferId) {
    return repository.observeTransfer(transferId);
  }
}
