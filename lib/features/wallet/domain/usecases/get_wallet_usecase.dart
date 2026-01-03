import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetWalletUseCase {
  final WalletRepository _repository;

  GetWalletUseCase(this._repository);

  Future<Result<WalletEntity>> call() {
    return _repository.getWallet();
  }
}
