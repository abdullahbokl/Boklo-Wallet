import 'package:injectable/injectable.dart';

// ignore: one_member_abstracts, justification: "Template interface."
abstract class AuthRemoteDataSource {
  Future<void> login(String email, String password);
  Future<void> logout();
  Future<void>
  getCurrentUser(); // Returns void for now as we don't have UserDto yet
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<void> login(String email, String password) async {
    // Implementation
  }

  @override
  Future<void> logout() async {
    // Implementation
  }

  @override
  Future<void> getCurrentUser() async {
    // Implementation
  }
}
