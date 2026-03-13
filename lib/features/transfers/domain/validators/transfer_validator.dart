import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferValidator {
  Either<Failure, void> validate({
    required WalletEntity fromWallet,
    required WalletEntity toWallet,
    required double amount,
  }) {
    if (amount <= 0) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }

    if (fromWallet.id == toWallet.id) {
      return const Left(
        ValidationFailure('Cannot transfer to the same wallet'),
      );
    }

    if (fromWallet.currency != toWallet.currency) {
      return const Left(
        ValidationFailure('Wallets must utilize the same currency'),
      );
    }

    if (fromWallet.balance < amount) {
      return const Left(ValidationFailure('Insufficient balance'));
    }

    return const Right(null);
  }
}
