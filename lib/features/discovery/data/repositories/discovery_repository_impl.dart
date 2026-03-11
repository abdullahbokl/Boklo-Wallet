import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/discovery/data/datasources/discovery_remote_data_source.dart';
import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DiscoveryRepository)
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl(this._dataSource);

  final DiscoveryRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, UserPublicProfile>> resolveWalletByEmail(String email) async {
    try {
      final model = await _dataSource.resolveWalletByEmail(email);
      return Right(model);
      // Map generic exceptions to AppError
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      final message = e.toString();
      if (message.contains('User not found')) {
        return const Left(ServerFailure('User not found'));
      }
      if (message.contains('User inactive')) {
        return const Left(ServerFailure('User is inactive'));
      }
      return Left(UnknownFailure('Failed to resolve wallet: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> resolveWalletIdByAlias(String alias) async {
    try {
      final walletId = await _dataSource.resolveWalletIdByAlias(alias);
      return Right(walletId);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      final message = e.toString();
      if (message.contains('Wallet alias not found')) {
        return const Left(ServerFailure('Wallet alias not found'));
      }
      return Left(UnknownFailure('Failed to resolve wallet alias: $e'));
    }
  }

  @override
  Future<Either<Failure, UserPublicProfile>> resolveWalletByUsername(
      String username) async {
    try {
      final model = await _dataSource.resolveWalletByUsername(username);
      return Right(model);
    } catch (e) {
      final message = e.toString();
      if (message.contains('Username not found')) {
        return const Left(ServerFailure('Username not found'));
      }
      return Left(UnknownFailure('Failed to resolve username: $e'));
    }
  }
}
