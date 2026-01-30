import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:injectable/injectable.dart';

@injectable
class ProvisionWalletUseCase {
  ProvisionWalletUseCase(this._remoteDataSource);

  final WalletRemoteDataSource _remoteDataSource;

  Future<Result<void>> call() async {
    try {
      await _remoteDataSource.provisionWallet();
      return const Success(null);
    } catch (e) {
      if (e is AppError) {
        return Failure(e);
      }
      return Failure(UnknownError('Failed to provision wallet: $e'));
    }
  }
}
