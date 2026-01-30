import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['name'] as String? ?? json['displayName'] as String?,
      username: json['username'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : (json['createdAt'] is String)
              ? DateTime.parse(json['createdAt'] as String)
              : (json['createdAt'] as dynamic).toDate()
                  as DateTime?, // Handle Timestamp
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final DateTime? createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (displayName != null) 'name': displayName,
      if (username != null) 'username': username,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      username: username,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
