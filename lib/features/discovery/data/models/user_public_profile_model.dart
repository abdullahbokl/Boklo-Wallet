import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';

class UserPublicProfileModel extends UserPublicProfile {
  const UserPublicProfileModel({
    required super.userId,
    required super.email,
    required super.walletId,
  });

  factory UserPublicProfileModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'id' and 'uid' keys (UserModel saves as 'id')
    final userId = json['uid'] as String? ?? json['id'] as String? ?? '';

    return UserPublicProfileModel(
      userId: userId,
      email: json['email'] as String? ?? '',
      // Default to userId if walletId is missing (1:1 mapping)
      walletId: json['walletId'] as String? ?? userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': userId,
      'email': email,
      'walletId': walletId,
    };
  }

  UserPublicProfile toEntity() {
    return UserPublicProfile(
      userId: userId,
      email: email,
      walletId: walletId,
    );
  }
}
