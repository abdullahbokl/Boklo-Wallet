import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/request_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransferValidator extends Mock implements TransferValidator {}

void main() {
  late RequestTransferUseCase useCase;
  late MockTransferValidator mockValidator;

  setUpAll(() {
    registerFallbackValue(
      const WalletEntity(
        id: 'fallback',
        balance: 0,
        currency: 'SAR',
        alias: null,
      ),
    );
  });

  setUp(() {
    mockValidator = MockTransferValidator();
    useCase = RequestTransferUseCase(mockValidator);
  });

  const tFromWallet = WalletEntity(
    id: '1',
    balance: 100,
    currency: 'SAR',
    alias: null,
  );

  const tToWallet = WalletEntity(
    id: '2',
    balance: 50,
    currency: 'SAR',
    alias: null,
  );

  test(
      'should return TransferEntity with status PENDING when validation succeeds',
      () async {
    // Arrange
    when(() => mockValidator.validate(
          fromWallet: any(named: 'fromWallet'),
          toWallet: any(named: 'toWallet'),
          amount: any(named: 'amount'),
        )).thenReturn(const Success(null));

    // Act
    final result = await useCase.call(
      fromWallet: tFromWallet,
      toWallet: tToWallet,
      amount: 10.0,
    );

    // Assert
    expect(result, isA<Success<TransferEntity>>());
    final transfer = (result as Success<TransferEntity>).data;
    expect(transfer.status, TransferStatus.pending);
    expect(transfer.amount, 10.0);
    expect(transfer.fromWalletId, tFromWallet.id);
    expect(transfer.toWalletId, tToWallet.id);
  });

  test('should return Failure when validation fails', () async {
    // Arrange
    const tError = ValidationError('Insufficient balance');
    when(() => mockValidator.validate(
          fromWallet: any(named: 'fromWallet'),
          toWallet: any(named: 'toWallet'),
          amount: any(named: 'amount'),
        )).thenReturn(const Failure(tError));

    // Act
    final result = await useCase.call(
      fromWallet: tFromWallet,
      toWallet: tToWallet,
      amount: 1000.0,
    );

    // Assert
    expect(result, isA<Failure<TransferEntity>>());
    expect((result as Failure).error, tError);
  });
}
