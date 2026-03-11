import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';

// Repository pattern requires abstract class interface
// ignore: one_member_abstracts
abstract class DiscoveryRepository {
  Future<Either<Failure, UserPublicProfile>> resolveWalletByEmail(String email);
  Future<Either<Failure, String>> resolveWalletIdByAlias(String alias);
  Future<Either<Failure, UserPublicProfile>> resolveWalletByUsername(String username);
}
