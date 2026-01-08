import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/data/repositories/transfer_repository_impl.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
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

  final walletModelA = const WalletModel(
    id: 'walletA',
    balance: 1000,
    currency: 'USD',
  );
  final walletModelB = const WalletModel(
    id: 'walletB',
    balance: 500,
    currency: 'USD',
  );

  final transferEntity = TransferEntity(
    id: 'tx1',
    fromWalletId: 'walletA',
    toWalletId: 'walletB',
    amount: 100,
    currency: 'USD',
    status: TransferStatus.pending,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockDataSource = MockTransferRemoteDataSource();
    mockValidator = MockTransferValidator();
    repository = TransferRepositoryImpl(mockDataSource, mockValidator);

    registerFallbackValue(
      const WalletEntity(id: 'fallback', balance: 0, currency: 'USD'),
    );
    registerFallbackValue(
      TransferModel(
        id: '1',
        fromWalletId: 'a',
        toWalletId: 'b',
        amount: 1,
        currency: 'USD',
        status: TransferStatus.pending,
        createdAt: DateTime(2023),
      ),
    );
  });

  group('TransferRepositoryImpl', () {
    test('should return Success when transfer is valid and checks pass',
        () async {
      // Arrange
      when(() => mockDataSource.getWallet('walletA'))
          .thenAnswer((_) async => walletModelA);
      when(() => mockDataSource.getWallet('walletB'))
          .thenAnswer((_) async => walletModelB);
      when(
        () => mockValidator.validate(
          fromWallet: any(named: 'fromWallet'),
          toWallet: any(named: 'toWallet'),
          amount: any(named: 'amount'),
        ),
      ).thenReturn(const Success(null));
      when(() => mockDataSource.createTransfer(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.createTransfer(transferEntity);

      // Assert
      expect(result, isA<Success<void>>());
      verify(() => mockDataSource.createTransfer(any())).called(1);
    });

    test('should return Failure when validation fails', () async {
      // Arrange
      when(() => mockDataSource.getWallet('walletA'))
          .thenAnswer((_) async => walletModelA);
      when(() => mockDataSource.getWallet('walletB'))
          .thenAnswer((_) async => walletModelB);
      when(
        () => mockValidator.validate(
          fromWallet: any(named: 'fromWallet'),
          toWallet: any(named: 'toWallet'),
          amount: any(named: 'amount'),
        ),
      ).thenReturn(const Failure(ValidationError('Validation failed')));

      // Act
      final result = await repository.createTransfer(transferEntity);

      // Assert
      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure).error,
        const ValidationError('Validation failed'),
      );
      verifyNever(() => mockDataSource.createTransfer(any()));
    });

    test('should resolve alias correctly', () async {
      // Create a transfer object that uses an alias
      final transferWithAlias = TransferEntity(
        id: transferEntity.id,
        fromWalletId: transferEntity.fromWalletId,
        toWalletId: 'BOKLO-123',
        amount: transferEntity.amount,
        currency: transferEntity.currency,
        status: transferEntity.status,
        createdAt: transferEntity.createdAt,
      );

      // Setup call to getWallet for sender
      when(() => mockDataSource.getWallet('walletA'))
          .thenAnswer((_) async => walletModelA);

      // Setup call to getWalletByAlias for recipient
      when(() => mockDataSource.getWalletByAlias('BOKLO-123'))
          .thenAnswer((_) async => walletModelB);

      // Setup validation to pass
      when(
        () => mockValidator.validate(
          fromWallet: any(named: 'fromWallet'),
          toWallet: any(named: 'toWallet'),
          amount: any(named: 'amount'),
        ),
      ).thenReturn(const Success(null));

      // Setup createTransfer to succeed
      when(() => mockDataSource.createTransfer(any()))
          .thenAnswer((_) async => {});

      // Apply
      await repository.createTransfer(transferWithAlias);

      // Verify alias lookup was called
      verify(() => mockDataSource.getWalletByAlias('BOKLO-123')).called(1);

      // Verify createTransfer was called with the RESOLVED wallet ID (walletB)
      final captured = verify(
        () => mockDataSource.createTransfer(captureAny()),
      ).captured.first as TransferModel;

      expect(captured.toWalletId, 'walletB');
    });

    test('should return Failure when wallet not found', () async {
      when(() => mockDataSource.getWallet('walletA'))
          .thenAnswer((_) async => walletModelA);
      when(() => mockDataSource.getWallet('walletB'))
          .thenAnswer((_) async => null);

      final result = await repository.createTransfer(transferEntity);

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure).error,
        const ValidationError('One or both wallets not found'),
      );
    });
    test(
        'should return Failure with sanitized message when createTransfer fails',
        () async {
      // Arrange
      when(() => mockDataSource.getWallet('walletA'))
          .thenAnswer((_) async => walletModelA);
      when(() => mockDataSource.getWallet('walletB'))
          .thenAnswer((_) async => walletModelB);
      when(
        () => mockValidator.validate(
          fromWallet: any(named: 'fromWallet'),
          toWallet: any(named: 'toWallet'),
          amount: any(named: 'amount'),
        ),
      ).thenReturn(const Success(null));

      // Simulate generic exception
      when(() => mockDataSource.createTransfer(any()))
          .thenThrow(Exception('Firestore offline or something'));

      // Act
      final result = await repository.createTransfer(transferEntity);

      // Assert
      expect(result, isA<Failure<void>>());
      final failure = result as Failure;
      expect(failure.error, isA<UnknownError>());
      // Verify sanitization
      expect(failure.error.message, 'Failed to create transfer');
      // Original error should be preserved as cause
      expect(failure.error.cause.toString(), contains('Firestore offline'));
    });
  });
}
