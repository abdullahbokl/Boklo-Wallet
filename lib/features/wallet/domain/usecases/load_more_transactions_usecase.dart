import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_page.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoadMoreTransactionsUseCase {
  final WalletRepository _repository;

  LoadMoreTransactionsUseCase(this._repository);

  Future<Either<Failure, TransactionPage>> call() {
    return _repository.loadMoreTransactions();
  }
}
