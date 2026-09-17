import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

class SetUserProfileParams {
  SetUserProfileParams({required this.username, this.name});

  final String username;
  final String? name;
}

@lazySingleton
class SetUserProfileUseCase implements UseCase<void, SetUserProfileParams> {
  SetUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(SetUserProfileParams params) =>
      _repository.setUserProfile(username: params.username, name: params.name);
}
