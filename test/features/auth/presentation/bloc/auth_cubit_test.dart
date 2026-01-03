import 'package:bloc_test/bloc_test.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/login_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late AuthCubit cubit;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    cubit = AuthCubit(
      mockLoginUseCase,
      mockLogoutUseCase,
      mockGetCurrentUserUseCase,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password';
  const tUser = User(id: '1', email: tEmail, displayName: 'Test User');
  const tError = UnknownError('Test error');

  group('AuthCubit', () {
    test('initial state is BaseState.initial', () {
      expect(cubit.state, const BaseState<User?>.initial());
    });

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success] when login is successful',
      build: () {
        when(() => mockLoginUseCase.call(tEmail, tPassword))
            .thenAnswer((_) async => const Success<User>(tUser));
        return cubit;
      },
      act: (cubit) => cubit.login(tEmail, tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(tUser),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase.call(tEmail, tPassword)).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, error] when login fails',
      build: () {
        when(() => mockLoginUseCase.call(tEmail, tPassword))
            .thenAnswer((_) async => const Failure<User>(tError));
        return cubit;
      },
      act: (cubit) => cubit.login(tEmail, tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.error(tError),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase.call(tEmail, tPassword)).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success(null)] when logout is successful',
      build: () {
        when(() => mockLogoutUseCase.call())
            .thenAnswer((_) async => const Success<void>(null));
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(null),
      ],
      verify: (_) {
        verify(() => mockLogoutUseCase.call()).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, error] when logout fails',
      build: () {
        when(() => mockLogoutUseCase.call())
            .thenAnswer((_) async => const Failure<void>(tError));
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.error(tError),
      ],
      verify: (_) {
        verify(() => mockLogoutUseCase.call()).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success] when checkAuthStatus finds a user',
      build: () {
        when(() => mockGetCurrentUserUseCase.call())
            .thenAnswer((_) async => const Success<User?>(tUser));
        return cubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(tUser),
      ],
      verify: (_) {
        verify(() => mockGetCurrentUserUseCase.call()).called(1);
      },
    );
  });
}
