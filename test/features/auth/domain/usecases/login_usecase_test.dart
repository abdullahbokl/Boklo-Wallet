import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = User(id: '1', email: tEmail, displayName: 'Test User');
  final tLoginParams = LoginParams(email: tEmail, password: tPassword);

  test('should return User when login is successful', () async {
    // Arrange
    when(() => mockAuthRepository.login(tEmail, tPassword))
        .thenAnswer((_) async => right(tUser));

    // Act
    final result = await loginUseCase(tLoginParams);

    // Assert
    expect(result, isA<Right<Failure, User>>());
    result.fold(
      (error) => fail('Expected Success but got Failure: $error'),
      (user) => expect(user, tUser),
    );
    verify(() => mockAuthRepository.login(tEmail, tPassword)).called(1);
  });

  test('should return Failure when login fails', () async {
    // Arrange
    const tError = UnknownFailure('Login failed');
    when(() => mockAuthRepository.login(tEmail, tPassword))
        .thenAnswer((_) async => left(tError));

    // Act
    final result = await loginUseCase(tLoginParams);

    // Assert
    expect(result, isA<Left<Failure, User>>());
    result.fold(
      (error) => expect(error, tError),
      (user) => fail('Expected Failure but got Success: $user'),
    );
    verify(() => mockAuthRepository.login(tEmail, tPassword)).called(1);
  });
}
