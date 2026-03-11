import 'package:fpdart/fpdart.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/usecases/usecase.dart';
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
        .thenAnswer((_) async => right(null));

    // Act
    final result = await logoutUseCase(NoParams());

    // Assert
    expect(result, isA<Right<Failure, void>>());
    verify(() => mockAuthRepository.logout()).called(1);
  });

  test('should return Failure when logout fails', () async {
    // Arrange
    const tError = UnknownFailure('Logout failed');
    when(() => mockAuthRepository.logout())
        .thenAnswer((_) async => left(tError));

    // Act
    final result = await logoutUseCase(NoParams());

    // Assert
    expect(result, isA<Left<Failure, void>>());
    result.fold(
      (error) => expect(error, tError),
      (_) => fail('Expected Failure but got Success'),
    );
    verify(() => mockAuthRepository.logout()).called(1);
  });
}
