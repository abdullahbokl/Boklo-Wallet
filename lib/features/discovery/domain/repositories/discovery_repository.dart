import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';

// Repository pattern requires abstract class interface
// ignore: one_member_abstracts
abstract class DiscoveryRepository {
  Future<Result<UserPublicProfile>> resolveWalletByEmail(String email);
  Future<Result<String>> resolveWalletIdByAlias(String alias);
}
