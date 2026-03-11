import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetTransactionsUseCase {
  final WalletRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<Either<Failure, List<TransactionEntity>>> call() {
    return _repository.getTransactions();
  }

  Stream<Either<Failure, List<TransactionEntity>>> watch() {
    return _repository.watchTransactions();
  }
}
