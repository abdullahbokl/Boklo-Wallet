import 'package:boklo/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

/// Exposes the last successful remote wallet fetch time so the
/// presentation layer can flag stale (offline-fallback) data.
@injectable
class GetWalletCacheTimeUseCase {
  GetWalletCacheTimeUseCase(this._repository);

  final WalletRepository _repository;

  Future<int?> call() => _repository.lastWalletFetchMs();
}
