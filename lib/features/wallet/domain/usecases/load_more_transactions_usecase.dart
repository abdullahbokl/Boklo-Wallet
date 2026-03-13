import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_page.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoadMoreTransactionsUseCase {

  LoadMoreTransactionsUseCase(this._repository);
  final WalletRepository _repository;

  Future<Either<Failure, TransactionPage>> call() {
    return _repository.loadMoreTransactions();
  }
}
