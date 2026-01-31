import 'package:boklo/features/discovery/data/models/user_public_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

// Interface for retrieving user Public Profile
abstract class DiscoveryRemoteDataSource {
  Future<UserPublicProfileModel> resolveWalletByEmail(String email);
  Future<String> resolveWalletIdByAlias(String alias);
  Future<UserPublicProfileModel> resolveWalletByUsername(String username);
}

@LazySingleton(as: DiscoveryRemoteDataSource)
class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<UserPublicProfileModel> resolveWalletByEmail(String email) async {
    // O(1) lookup via wallet_identifiers mapping
    final emailLower = email.toLowerCase();
    final mappingDoc = await _firestore
        .collection('wallet_identifiers')
        .doc('email:$emailLower')
        .get();

    if (!mappingDoc.exists) {
      throw Exception('IDENTIFIER_NOT_REGISTERED');
    }

    final walletId = mappingDoc.data()?['walletId'] as String?;
    if (walletId == null) {
      throw Exception('Invalid identifier mapping');
    }

    final userDoc = await _firestore.collection('users').doc(walletId).get();

    if (!userDoc.exists) {
      throw Exception('User profile not found');
    }

    final data = userDoc.data()!;
    final isActive = data['isActive'] as bool? ?? true;

    if (!isActive) {
      throw Exception('User inactive');
    }

    return UserPublicProfileModel.fromJson(data);
  }

  @override
  Future<String> resolveWalletIdByAlias(String alias) async {
    final snapshot = await _firestore
        .collection('wallets')
        .where('alias', isEqualTo: alias)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Wallet alias not found');
    }

    // The document ID is the Wallet ID (User ID)
    return snapshot.docs.first.id;
  }

  @override
  Future<UserPublicProfileModel> resolveWalletByUsername(
    String username,
  ) async {
    // O(1) lookup via wallet_identifiers mapping
    final usernameLower = username.toLowerCase().replaceAll('@', '');
    final mappingDoc = await _firestore
        .collection('wallet_identifiers')
        .doc('username:$usernameLower')
        .get();

    if (!mappingDoc.exists) {
      throw Exception('IDENTIFIER_NOT_REGISTERED');
    }

    final walletId = mappingDoc.data()?['walletId'] as String?;
    if (walletId == null) {
      throw Exception('Invalid identifier mapping');
    }

    final userDoc = await _firestore.collection('users').doc(walletId).get();

    if (!userDoc.exists) {
      throw Exception('User profile not found');
    }

    return UserPublicProfileModel.fromJson(userDoc.data()!);
  }
}
