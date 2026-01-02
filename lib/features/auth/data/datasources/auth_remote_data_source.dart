import 'package:injectable/injectable.dart';

// ignore: one_member_abstracts, justification: "Template interface."
abstract class AuthRemoteDataSource {
  Future<void> login(String email, String password);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<void> login(String email, String password) async {
    // Implementation
  }
}
