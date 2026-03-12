import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/data/datasources/user_remote_data_source.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

class SetUserProfileParams {
  SetUserProfileParams({required this.username, this.name});

  final String username;
  final String? name;
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
    } on Failure catch (e) {
      return Left(e);
    } on Object catch (e) {
      return Left(UnknownFailure('Failed to set profile: $e'));
    }
  }
}
