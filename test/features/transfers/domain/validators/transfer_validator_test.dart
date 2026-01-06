import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/transfers/domain/validators/transfer_validator.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TransferValidator validator;
  late WalletEntity walletA;
  late WalletEntity walletB;

  setUp(() {
    validator = TransferValidator();
    walletA = const WalletEntity(
      id: 'walletA',
      balance: 1000,
      currency: 'USD',
    );
    walletB = const WalletEntity(
      id: 'walletB',
      balance: 500,
      currency: 'USD',
    );
  });

  group('TransferValidator', () {
    test('should return Success when all rules are met', () {
      final result = validator.validate(
        fromWallet: walletA,
        toWallet: walletB,
        amount: 100,
      );

      expect(result, isA<Success<void>>());
    });

    test('should return Failure when amount is zero or negative', () {
      final resultZero = validator.validate(
        fromWallet: walletA,
        toWallet: walletB,
        amount: 0,
      );
      final resultNeg = validator.validate(
        fromWallet: walletA,
        toWallet: walletB,
        amount: -10,
      );

      expect(resultZero, isA<Failure<void>>());
      expect(
        (resultZero as Failure).error,
        const ValidationError('Amount must be greater than zero'),
      );
      expect(resultNeg, isA<Failure<void>>());
    });

    test('should return Failure when sender and receiver are the same', () {
      final result = validator.validate(
        fromWallet: walletA,
        toWallet: walletA,
        amount: 100,
      );

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure).error,
        const ValidationError('Cannot transfer to the same wallet'),
      );
    });

    test('should return Failure when currencies do not match', () {
      final walletC = walletB.copyWith(currency: 'EUR');
      final result = validator.validate(
        fromWallet: walletA,
        toWallet: walletC,
        amount: 100,
      );

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure).error,
        const ValidationError('Wallets must utilize the same currency'),
      );
    });

    test('should return Failure when balance is insufficient', () {
      final result = validator.validate(
        fromWallet: walletA,
        toWallet: walletB,
        amount: 1500,
      );

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure).error,
        const ValidationError('Insufficient balance'),
      );
    });
  });
}
