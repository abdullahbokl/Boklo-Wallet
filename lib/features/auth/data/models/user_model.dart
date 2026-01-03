import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (displayName != null) 'displayName': displayName,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
    );
  }
}
