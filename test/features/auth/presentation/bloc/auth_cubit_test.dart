import 'package:bloc_test/bloc_test.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/core/services/notification_service.dart';
import 'package:boklo/core/usecases/usecase.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/login_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/register_usecase.dart';
import 'package:boklo/features/auth/domain/usecases/set_user_profile_usecase.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockDeleteAccountUseCase extends Mock implements DeleteAccountUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockSetUserProfileUseCase extends Mock implements SetUserProfileUseCase {}

class FakeLoginParams extends Fake implements LoginParams {}

class FakeNoParams extends Fake implements NoParams {}

class FakeRegisterParams extends Fake implements RegisterParams {}

class FakeSetUserProfileParams extends Fake implements SetUserProfileParams {}

class FakeDeleteAccountParams extends Fake implements DeleteAccountParams {}

void main() {
  late AuthCubit cubit;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockDeleteAccountUseCase mockDeleteAccountUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockSetUserProfileUseCase mockSetUserProfileUseCase;
  late MockAnalyticsService mockAnalyticsService;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(FakeLoginParams());
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeRegisterParams());
    registerFallbackValue(FakeSetUserProfileParams());
    registerFallbackValue(FakeDeleteAccountParams());
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockDeleteAccountUseCase = MockDeleteAccountUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockSetUserProfileUseCase = MockSetUserProfileUseCase();
    mockAnalyticsService = MockAnalyticsService();
    mockNotificationService = MockNotificationService();

    when(() => mockAnalyticsService.logLogin(method: any(named: 'method')))
        .thenAnswer((_) async {});

    when(() => mockNotificationService.deleteToken()).thenAnswer((_) async {});

    cubit = AuthCubit(
      mockLoginUseCase,
      mockLogoutUseCase,
      mockDeleteAccountUseCase,
      mockGetCurrentUserUseCase,
      mockRegisterUseCase,
      mockSetUserProfileUseCase,
      mockAnalyticsService,
      mockNotificationService,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password';
  const tUser = User(id: '1', email: tEmail, displayName: 'Test User');
  const tError = UnknownFailure('Test error');

  group('AuthCubit', () {
    test('initial state is BaseState.initial', () {
      expect(cubit.state, const BaseState<User?>.initial());
    });

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success] when login is successful',
      build: () {
        when(() => mockLoginUseCase.call(any()))
            .thenAnswer((_) async => right(tUser));
        return cubit;
      },
      act: (cubit) => cubit.login(tEmail, tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(tUser),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, error] when login fails',
      build: () {
        when(() => mockLoginUseCase.call(any()))
            .thenAnswer((_) async => left(tError));
        return cubit;
      },
      act: (cubit) => cubit.login(tEmail, tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.error(tError),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success(null)] when logout is successful',
      build: () {
        when(() => mockLogoutUseCase.call(any()))
            .thenAnswer((_) async => right(null));
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(null),
      ],
      verify: (_) {
        verify(() => mockLogoutUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, error] when logout fails',
      build: () {
        when(() => mockLogoutUseCase.call(any()))
            .thenAnswer((_) async => left(tError));
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.error(tError),
      ],
      verify: (_) {
        verify(() => mockLogoutUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success(null)] when account deletion succeeds',
      build: () {
        when(() => mockDeleteAccountUseCase.call(any()))
            .thenAnswer((_) async => right(null));
        when(() => mockLogoutUseCase.call(any()))
            .thenAnswer((_) async => right(null));
        return cubit;
      },
      act: (cubit) => cubit.deleteAccount(tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(null),
      ],
      verify: (_) {
        verify(() => mockDeleteAccountUseCase.call(any())).called(1);
        verify(() => mockNotificationService.deleteToken()).called(1);
        verify(() => mockLogoutUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, error] when account deletion fails',
      build: () {
        when(() => mockDeleteAccountUseCase.call(any()))
            .thenAnswer((_) async => left(tError));
        return cubit;
      },
      act: (cubit) => cubit.deleteAccount(tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.error(tError),
      ],
      verify: (_) {
        verify(() => mockDeleteAccountUseCase.call(any())).called(1);
        verifyNever(() => mockLogoutUseCase.call(any()));
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success] when checkAuthStatus finds a user',
      build: () {
        when(() => mockGetCurrentUserUseCase.call(any()))
            .thenAnswer((_) async => right(tUser));
        return cubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(tUser),
      ],
      verify: (_) {
        verify(() => mockGetCurrentUserUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, success] when register is successful',
      build: () {
        when(() => mockRegisterUseCase.call(any()))
            .thenAnswer((_) async => right(tUser));
        return cubit;
      },
      act: (cubit) => cubit.register(tEmail, tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(tUser),
      ],
      verify: (_) {
        verify(() => mockRegisterUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, error] when register fails',
      build: () {
        when(() => mockRegisterUseCase.call(any()))
            .thenAnswer((_) async => left(tError));
        return cubit;
      },
      act: (cubit) => cubit.register(tEmail, tPassword),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.error(tError),
      ],
      verify: (_) {
        verify(() => mockRegisterUseCase.call(any())).called(1);
      },
    );

    blocTest<AuthCubit, BaseState<User?>>(
      'emits [loading, loading, success] when setUserProfile is successful',
      build: () {
        when(() => mockSetUserProfileUseCase.call(any()))
            .thenAnswer((_) async => right(null));
        when(() => mockGetCurrentUserUseCase.call(any()))
            .thenAnswer((_) async => right(tUser));
        return cubit;
      },
      act: (cubit) =>
          cubit.setUserProfile(username: 'testuser', name: 'Test Name'),
      expect: () => const [
        BaseState<User?>.loading(),
        BaseState<User?>.success(tUser),
      ],
      verify: (_) {
        verify(() => mockSetUserProfileUseCase.call(any())).called(1);
        verify(() => mockGetCurrentUserUseCase.call(any())).called(1);
      },
    );
  });
}
