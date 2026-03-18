import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

class DeleteAccountParams {
  DeleteAccountParams({required this.password});

  final String password;
}

@injectable
class DeleteAccountUseCase implements UseCase<void, DeleteAccountParams> {
  DeleteAccountUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) {
    return _repository.deleteAccount(params.password);
  }
}
