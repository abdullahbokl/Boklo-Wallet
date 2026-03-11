import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:injectable/injectable.dart';

class SetUserProfileParams {
  final String username;
  final String? name;
  SetUserProfileParams({required this.username, this.name});
}

@lazySingleton
class SetUserProfileUseCase implements UseCase<void, SetUserProfileParams> {
  SetUserProfileUseCase(this._userRemoteDataSource);

  final UserRemoteDataSource _userRemoteDataSource;

  @override
  Future<Either<Failure, void>> call(SetUserProfileParams params) async {
    try {
      await _userRemoteDataSource.setUserProfile(
        username: params.username,
        name: params.name,
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to set profile: $e'));
    }
  }
}
