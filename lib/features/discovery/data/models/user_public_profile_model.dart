import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';

class UserPublicProfileModel extends UserPublicProfile {
  const UserPublicProfileModel({
    required super.userId,
    required super.email,
    required super.walletId,
  });

  factory UserPublicProfileModel.fromJson(Map<String, dynamic> json) {
    return UserPublicProfileModel(
      userId: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
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
