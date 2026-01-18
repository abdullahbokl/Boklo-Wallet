import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/data/models/wallet_model.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransferRemoteDataSource extends Mock
    implements TransferRemoteDataSource {}

class MockTransferValidator extends Mock implements TransferValidator {}

void main() {
  late TransferRepositoryImpl repository;
  late MockTransferRemoteDataSource mockDataSource;
  late MockTransferValidator mockValidator;

  setUp(() {
    mockDataSource = MockTransferRemoteDataSource();
    mockValidator = MockTransferValidator();
    repository = TransferRepositoryImpl(mockDataSource, mockValidator);
  });

  const tWalletModel = WalletModel(
    id: 'wallet-123',
    balance: 100,
    currency: 'USD',
    alias: 'BOKLO-123',
    email: 'alice@example.com',
  );

  group('getWallet (Unified Resolution)', () {
    test('should resolve by Email when input contains @', () async {
      // Arrange
      when(() => mockDataSource.getWalletByEmail('alice@example.com'))
          .thenAnswer((_) async => tWalletModel);

      // Act
      final result = await repository.getWallet('alice@example.com');

      // Assert
      verify(() => mockDataSource.getWalletByEmail('alice@example.com'))
          .called(1);
      verifyNever(() => mockDataSource.getWallet(any()));
      expect(result, isA<Success<WalletEntity>>());
      expect((result as Success).data.id, tWalletModel.id);
    });

    test('should resolve by Alias when input starts with BOKLO-', () async {
      // Arrange
      when(() => mockDataSource.getWalletByAlias('BOKLO-123'))
          .thenAnswer((_) async => tWalletModel);

      // Act
      final result = await repository.getWallet('BOKLO-123');

      // Assert
      verify(() => mockDataSource.getWalletByAlias('BOKLO-123')).called(1);
      verifyNever(() => mockDataSource.getWallet(any()));
      expect(result, isA<Success<WalletEntity>>());
    });

    test('should resolve by ID when input is normal string', () async {
      // Arrange
      when(() => mockDataSource.getWallet('wallet-123'))
          .thenAnswer((_) async => tWalletModel);

      // Act
      final result = await repository.getWallet('wallet-123');

      // Assert
      verify(() => mockDataSource.getWallet('wallet-123')).called(1);
      verifyNever(() => mockDataSource.getWalletByEmail(any()));
      expect(result, isA<Success<WalletEntity>>());
    });

    test('should return Failure when wallet not found', () async {
      // Arrange
      when(() => mockDataSource.getWalletByEmail('unknown@example.com'))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getWallet('unknown@example.com');

      // Assert
      expect(result, isA<Failure<WalletEntity>>());
      expect((result as Failure).error, isA<ValidationError>());
    });
  });
}
