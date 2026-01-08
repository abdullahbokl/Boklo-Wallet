import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveWalletByEmailUseCase {
  ResolveWalletByEmailUseCase(this._repository);

  final DiscoveryRepository _repository;

  Future<Result<String>> call(String email) async {
    final result = await _repository.resolveWalletByEmail(email);

    return result.fold(
      Failure.new,
      (profile) => Success(profile.walletId),
    );
  }
}
