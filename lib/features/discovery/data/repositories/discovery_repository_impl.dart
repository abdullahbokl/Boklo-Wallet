import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/discovery/data/datasources/discovery_remote_data_source.dart';
import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DiscoveryRepository)
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl(this._dataSource);

  final DiscoveryRemoteDataSource _dataSource;

  @override
  Future<Result<UserPublicProfile>> resolveWalletByEmail(String email) async {
    try {
      final model = await _dataSource.resolveWalletByEmail(email);
      return Success(model);
      // Map generic exceptions to AppError
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      final message = e.toString();
      if (message.contains('User not found')) {
        return const Failure(ValidationError('User not found'));
      }
      if (message.contains('User inactive')) {
        return const Failure(ValidationError('User is inactive'));
      }
      return Failure(UnknownError('Failed to resolve wallet', e));
    }
  }

  @override
  Future<Result<String>> resolveWalletIdByAlias(String alias) async {
    try {
      final walletId = await _dataSource.resolveWalletIdByAlias(alias);
      return Success(walletId);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      final message = e.toString();
      if (message.contains('Wallet alias not found')) {
        return const Failure(ValidationError('Wallet alias not found'));
      }
      return Failure(UnknownError('Failed to resolve wallet alias', e));
    }
  }
}
