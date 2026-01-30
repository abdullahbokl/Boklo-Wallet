import 'package:boklo/features/discovery/data/models/user_public_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

// Interface for retrieving user Public Profile
// ignore: one_member_abstracts
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
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('User not found');
    }

    final data = snapshot.docs.first.data();
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
      String username) async {
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();

    if (!usernameDoc.exists) {
      throw Exception('Username not found');
    }

    final uid = usernameDoc.data()?['uid'] as String?;
    if (uid == null) {
      throw Exception('Invalid username record');
    }

    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      throw Exception('User profile not found');
    }

    return UserPublicProfileModel.fromJson(userDoc.data()!);
  }
}
