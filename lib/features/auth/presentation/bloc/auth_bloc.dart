import 'package:bloc/bloc.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthBloc extends Bloc<dynamic, dynamic> {
  AuthBloc(this.repository) : super(null);

  final AuthRepository repository;
}
