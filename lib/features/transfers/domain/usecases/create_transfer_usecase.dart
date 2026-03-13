import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateTransferUseCase {
  CreateTransferUseCase(this._repository);

  final TransferRepository _repository;

  Future<Either<Failure, void>> call(TransferEntity transfer) {
    return _repository.createTransfer(transfer);
  }
}
