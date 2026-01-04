import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetTransfersUseCase {
  GetTransfersUseCase(this._repository);

  final TransferRepository _repository;

  Future<Result<List<TransferEntity>>> call() {
    return _repository.getTransfers();
  }
}
