import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveWalletByUsernameUseCase {
  ResolveWalletByUsernameUseCase(this._repository);

  final DiscoveryRepository _repository;

  Future<Either<Failure, String>> call(String username) async {
    final result = await _repository.resolveWalletByUsername(username);

    return result.fold(
      left,
      (profile) => right(profile.walletId),
    );
  }
}
