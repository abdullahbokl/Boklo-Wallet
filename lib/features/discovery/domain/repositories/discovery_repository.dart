import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';
import 'package:fpdart/fpdart.dart';

// Repository pattern requires abstract class interface
abstract class DiscoveryRepository {
  Future<Either<Failure, UserPublicProfile>> resolveWalletByEmail(String email);
  Future<Either<Failure, String>> resolveWalletIdByAlias(String alias);
  Future<Either<Failure, UserPublicProfile>> resolveWalletByUsername(String username);
}
