import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_limits.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetTransferLimitsUseCase {
  GetTransferLimitsUseCase(this._repository);

  final TransferRepository _repository;

  Future<Either<Failure, TransferLimits>> call() =>
      _repository.getTransferLimits();
}
