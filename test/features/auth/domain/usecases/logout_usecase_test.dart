import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart';
import 'package:boklo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LogoutUseCase logoutUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    logoutUseCase = LogoutUseCase(mockAuthRepository);
  });

  test('should return void when logout is successful', () async {
    // Arrange
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Success(null));

    // Act
    final result = await logoutUseCase();

    // Assert
    expect(result, isA<Success<void>>());
    verify(() => mockAuthRepository.logout()).called(1);
  });

  test('should return Failure when logout fails', () async {
    // Arrange
    const tError = UnknownError('Logout failed');
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => const Failure(tError));

    // Act
    final result = await logoutUseCase();

    // Assert
    expect(result, isA<Failure<void>>());
    result.fold(
      (error) => expect(error, tError),
      (_) => fail('Expected Failure but got Success'),
    );
    verify(() => mockAuthRepository.logout()).called(1);
  });
}
