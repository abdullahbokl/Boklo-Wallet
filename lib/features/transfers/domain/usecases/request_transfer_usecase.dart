import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@injectable
class RequestTransferUseCase {
  RequestTransferUseCase(
    this._validator,
    this._repository,
  );

  final TransferValidator _validator;
  final TransferRepository _repository;
  final _uuid = const Uuid();

  Future<Result<TransferEntity>> call({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
  }) async {
    // 0. Fetch Wallets
    final fromWalletResult = await _repository.getWallet(fromWalletId);
    final toWalletResult = await _repository.getWallet(toWalletId);

    if (fromWalletResult is Failure) {
      return Failure((fromWalletResult as Failure).error);
    }
    if (toWalletResult is Failure) {
      return Failure((toWalletResult as Failure).error);
    }

    final fromWallet = (fromWalletResult as Success<WalletEntity>).data;
    final toWallet = (toWalletResult as Success<WalletEntity>).data;

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
