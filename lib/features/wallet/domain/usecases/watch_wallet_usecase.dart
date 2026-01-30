import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class WatchWalletUseCase {
  final WalletRepository _repository;

  WatchWalletUseCase(this._repository);

  Stream<Result<WalletEntity>> call() {
    return _repository.watchWallet();
  }
}
