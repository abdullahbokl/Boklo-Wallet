import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:injectable/injectable.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
}

@LazySingleton(as: WalletRemoteDataSource)
class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  @override
  Future<WalletModel> getWallet() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return const WalletModel(
      id: 'wallet_123',
      balance: 1250.50,
      currency: 'USD',
    );
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return [
      TransactionModel(
        id: 'tx_1',
        amount: 50,
        type: TransactionType.debit,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: 'tx_2',
        amount: 300,
        type: TransactionType.credit,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
