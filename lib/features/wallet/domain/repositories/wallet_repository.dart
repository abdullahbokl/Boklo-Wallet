import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_page.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet();
  Future<Either<Failure, List<TransactionEntity>>> getTransactions();
  Future<Either<Failure, TransactionPage>> loadMoreTransactions();
  Stream<Either<Failure, List<TransactionEntity>>> watchTransactions();
  Stream<Either<Failure, WalletEntity>> watchWallet();
}
