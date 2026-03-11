import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetTransfersUseCase {
  GetTransfersUseCase(this._repository);

  final TransferRepository _repository;

  Future<Either<Failure, List<TransferEntity>>> call() {
    return _repository.getTransfers();
  }
}
