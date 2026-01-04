import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateTransferUseCase {
  CreateTransferUseCase(this._repository);

  final TransferRepository _repository;

  Future<Result<void>> call(TransferEntity transfer) {
    return _repository.createTransfer(transfer);
  }
}
