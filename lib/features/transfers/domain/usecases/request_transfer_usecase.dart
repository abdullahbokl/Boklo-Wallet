import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@injectable
class RequestTransferUseCase {
  RequestTransferUseCase(this._validator);

  final TransferValidator _validator;
  final _uuid = const Uuid();

  Future<Result<TransferEntity>> call({
    required WalletEntity fromWallet,
    required WalletEntity toWallet,
    required double amount,
  }) async {
    // 1. Validate
    final validationResult = _validator.validate(
      fromWallet: fromWallet,
      toWallet: toWallet,
      amount: amount,
    );

    if (validationResult is Failure) {
      return Failure(validationResult.error);
    }

    // 2. Create Pending Entity
    final transfer = TransferEntity(
      id: _uuid.v4(),
      fromWalletId: fromWallet.id,
      toWalletId: toWallet.id,
      amount: amount,
      currency: fromWallet.currency, // Verified same currency in validator
      status: TransferStatus.pending,
      createdAt: DateTime.now(),
    );

    // 3. Return (No local balance mutation)
    return Success(transfer);
  }
}
