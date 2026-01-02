import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  static User fromFirebaseUser(firebase_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
    );
  }
}
