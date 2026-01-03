import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetTransactionsUseCase {
  final WalletRepository _repository;

  GetTransactionsUseCase(this._repository);

  Future<Result<List<TransactionEntity>>> call() {
    return _repository.getTransactions();
  }
}
