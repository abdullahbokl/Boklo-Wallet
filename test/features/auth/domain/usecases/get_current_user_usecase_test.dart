import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUserUseCase getCurrentUserUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    getCurrentUserUseCase = GetCurrentUserUseCase(mockAuthRepository);
  });

  const tUser =
      User(id: '1', email: 'test@example.com', displayName: 'Test User');

  test(
      'should return User when check auth status is successful and user exists',
      () async {
    // Arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Success(tUser));

    // Act
    final result = await getCurrentUserUseCase();

    // Assert
    expect(result, isA<Success<User?>>());
    result.fold(
      (error) => fail('Expected Success but got Failure: $error'),
      (user) => expect(user, tUser),
    );
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
  });

  test(
      'should return null when check auth status is successful but no user exists',
      () async {
    // Arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Success(null));

    // Act
    final result = await getCurrentUserUseCase();

    // Assert
    expect(result, isA<Success<User?>>());
    result.fold(
      (error) => fail('Expected Success but got Failure: $error'),
      (user) => expect(user, isNull),
    );
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
  });

  test('should return Failure when check auth status fails', () async {
    // Arrange
    const tError = UnknownError('Check auth failed');
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Failure(tError));

    // Act
    final result = await getCurrentUserUseCase();

    // Assert
    expect(result, isA<Failure<User?>>());
    result.fold(
      (error) => expect(error, tError),
      (user) => fail('Expected Failure but got Success: $user'),
    );
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
  });
}
