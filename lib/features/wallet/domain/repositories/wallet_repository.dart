import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<Result<WalletEntity>> getWallet();
  Future<Result<List<TransactionEntity>>> getTransactions();
  Stream<Result<List<TransactionEntity>>> watchTransactions();
  Stream<Result<WalletEntity>> watchWallet();
}
