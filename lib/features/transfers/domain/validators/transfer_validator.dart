import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferValidator {
  Result<void> validate({
    required WalletEntity fromWallet,
    required WalletEntity toWallet,
    required double amount,
  }) {
    if (amount <= 0) {
      return const Failure(ValidationError('Amount must be greater than zero'));
    }

    if (fromWallet.id == toWallet.id) {
      return const Failure(
        ValidationError('Cannot transfer to the same wallet'),
      );
    }

    if (fromWallet.currency != toWallet.currency) {
      return const Failure(
        ValidationError('Wallets must utilize the same currency'),
      );
    }

    if (fromWallet.balance < amount) {
      return const Failure(ValidationError('Insufficient balance'));
    }

    return const Success(null);
  }
}
