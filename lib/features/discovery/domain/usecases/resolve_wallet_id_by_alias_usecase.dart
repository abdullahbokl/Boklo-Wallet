import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveWalletIdByAliasUseCase {
  ResolveWalletIdByAliasUseCase(this._repository);

  final DiscoveryRepository _repository;

  Future<Either<Failure, String>> call(String alias) async {
    return _repository.resolveWalletIdByAlias(alias);
  }
}
