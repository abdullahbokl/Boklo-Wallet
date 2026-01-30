import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SetUserProfileUseCase {
  SetUserProfileUseCase(this._userRemoteDataSource);

  final UserRemoteDataSource _userRemoteDataSource;

  Future<Result<void>> call({
    required String username,
    String? name,
  }) async {
    try {
      await _userRemoteDataSource.setUserProfile(
        username: username,
        name: name,
      );
      return const Success(null);
    } catch (e) {
      if (e is AppError) {
        return Failure(e);
      }
      return Failure(UnknownError('Failed to set profile: $e'));
    }
  }
}
