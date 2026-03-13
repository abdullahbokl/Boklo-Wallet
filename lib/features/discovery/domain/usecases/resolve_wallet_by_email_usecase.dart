import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveWalletByEmailUseCase {
  ResolveWalletByEmailUseCase(this._repository);

  final DiscoveryRepository _repository;

  Future<Either<Failure, String>> call(String email) async {
    final result = await _repository.resolveWalletByEmail(email);

    return result.fold(
      left,
      (profile) => right(profile.walletId),
    );
  }
}
