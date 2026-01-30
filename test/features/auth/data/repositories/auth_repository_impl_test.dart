import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:boklo/features/auth/data/models/user_model.dart';
import 'package:boklo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:boklo/features/auth/data/datasources/user_remote_data_source.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

class MockFirebaseAuthException extends Mock implements FirebaseAuthException {}

class FakeUserModel extends Fake implements UserModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserModel());
  });

  late AuthRepositoryImpl authRepository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockUserRemoteDataSource mockUserRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockUserRemoteDataSource = MockUserRemoteDataSource();
    authRepository = AuthRepositoryImpl(
      mockRemoteDataSource,
      mockUserRemoteDataSource,
    );
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUserModel = UserModel(
    id: '1',
    email: tEmail,
    displayName: 'Test User',
  );
  final tUser = tUserModel.toEntity();

  group('register', () {
    test('should return Success<User> when auth is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.register(any(), any()))
          .thenAnswer((_) async => tUserModel);

      // Act
      final result = await authRepository.register(tEmail, tPassword);

      // Assert
      expect(result, isA<Success<User>>());
      result.fold(
        (error) => fail('Expected Success but got Failure: $error'),
        (user) => expect(user, tUser),
      );
      verify(() => mockRemoteDataSource.register(tEmail, tPassword)).called(1);
    });

    test(
        'should return Failure with FirebaseError when auth fails with FirebaseAuthException',
        () async {
      // Arrange
      final tException = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email used',
      );
      when(() => mockRemoteDataSource.register(any(), any()))
          .thenThrow(tException);

      // Act
      final result = await authRepository.register(tEmail, tPassword);

      // Assert
      expect(result, isA<Failure<User>>());
      result.fold(
        (error) {
          expect(error, isA<FirebaseError>());
          expect((error as FirebaseError).code, 'email-already-in-use');
        },
        (user) => fail('Expected Failure but got Success'),
      );
      verify(() => mockRemoteDataSource.register(tEmail, tPassword)).called(1);
    });
  });

  group('login', () {
    test('should return Success<User> when login is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(any(), any()))
          .thenAnswer((_) async => tUserModel);
      when(() => mockUserRemoteDataSource.getUser(any()))
          .thenAnswer((_) async => tUserModel);

      // Act
      final result = await authRepository.login(tEmail, tPassword);

      // Assert
      expect(result, isA<Success<User>>());
      result.fold(
        (error) => fail('Expected Success but got Failure: $error'),
        (user) => expect(user, tUser),
      );
      verify(() => mockRemoteDataSource.login(tEmail, tPassword)).called(1);
      verify(() => mockUserRemoteDataSource.getUser(tUserModel.id)).called(1);
    });

    test(
        'should return Failure with FirebaseError when login fails with FirebaseAuthException',
        () async {
      // Arrange
      final tException = FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Invalid password',
      );
      when(() => mockRemoteDataSource.login(any(), any()))
          .thenThrow(tException);

      // Act
      final result = await authRepository.login(tEmail, tPassword);

      // Assert
      expect(result, isA<Failure<User>>());
      result.fold(
        (error) {
          expect(error, isA<FirebaseError>());
          expect((error as FirebaseError).code, 'invalid-credential');
        },
        (user) => fail('Expected Failure but got Success'),
      );
      verify(() => mockRemoteDataSource.login(tEmail, tPassword)).called(1);
    });

    test(
        'should return Failure with NetworkError when login fails with network-request-failed',
        () async {
      // Arrange
      final tException = FirebaseAuthException(
        code: 'network-request-failed',
        message: 'Network error',
      );
      when(() => mockRemoteDataSource.login(any(), any()))
          .thenThrow(tException);

      // Act
      final result = await authRepository.login(tEmail, tPassword);

      // Assert
      expect(result, isA<Failure<User>>());
      result.fold(
        (error) => expect(error, isA<NetworkError>()),
        (user) => fail('Expected Failure but got Success'),
      );
      verify(() => mockRemoteDataSource.login(tEmail, tPassword)).called(1);
    });

    test(
        'should return Failure with UnknownError when unknown exception occurs',
        () async {
      // Arrange
      final tException = Exception('Something went wrong');
      when(() => mockRemoteDataSource.login(any(), any()))
          .thenThrow(tException);

      // Act
      final result = await authRepository.login(tEmail, tPassword);

      // Assert
      expect(result, isA<Failure<User>>());
      result.fold(
        (error) => expect(error, isA<UnknownError>()),
        (user) => fail('Expected Failure but got Success'),
      );
      verify(() => mockRemoteDataSource.login(tEmail, tPassword)).called(1);
    });
  });

  group('logout', () {
    test('should return Success<void> when logout is successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout())
          .thenAnswer((_) => Future.value());

      // Act
      final result = await authRepository.logout();

      // Assert
      expect(result, isA<Success<void>>());
      verify(() => mockRemoteDataSource.logout()).called(1);
    });

    test('should return Failure when logout throws exception', () async {
      // Arrange
      final tException = Exception('Logout failed');
      when(() => mockRemoteDataSource.logout()).thenThrow(tException);

      // Act
      final result = await authRepository.logout();

      // Assert
      expect(result, isA<Failure<void>>());
      verify(() => mockRemoteDataSource.logout()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return Success<User> when user exists', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) => Future.value(tUserModel));
      when(() => mockUserRemoteDataSource.getUser(any()))
          .thenAnswer((_) async => tUserModel);

      // Act
      final result = await authRepository.getCurrentUser();

      // Assert
      expect(result, isA<Success<User?>>());
      result.fold(
        (error) => fail('Expected Success but got Failure'),
        (user) => expect(user, tUser),
      );
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      verify(() => mockUserRemoteDataSource.getUser(tUserModel.id)).called(1);
    });

    test('should return Success<null> when no user exists', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) => Future<UserModel?>.value(null));

      // Act
      final result = await authRepository.getCurrentUser();

      // Assert
      expect(result, isA<Success<User?>>());
      result.fold(
        (error) => fail('Expected Success but got Failure'),
        (user) => expect(user, isNull),
      );
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });
  });
}
