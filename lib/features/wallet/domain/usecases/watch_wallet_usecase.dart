import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class WatchWalletUseCase {

  WatchWalletUseCase(this._repository);
  final WalletRepository _repository;

  Stream<Either<Failure, WalletEntity>> call() {
    return _repository.watchWallet();
  }
}
