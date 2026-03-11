import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProvisionWalletUseCase {
  ProvisionWalletUseCase(this._remoteDataSource);

  final WalletRemoteDataSource _remoteDataSource;

  Future<Either<Failure, void>> call() async {
    try {
      await _remoteDataSource.provisionWallet();
      return right(null);
    } catch (e) {
      if (e is Failure) {
        return left(e);
      }
      return left(UnknownFailure('Failed to provision wallet: $e'));
    }
  }
}
