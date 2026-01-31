import 'package:bloc_test/bloc_test.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/usecases/get_transactions_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/provision_wallet_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/watch_wallet_usecase.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchWalletUseCase extends Mock implements WatchWalletUseCase {}

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

class MockProvisionWalletUseCase extends Mock
    implements ProvisionWalletUseCase {}

void main() {
  late WalletCubit cubit;
  late MockWatchWalletUseCase mockWatchWalletUseCase;
  late MockGetTransactionsUseCase mockGetTransactionsUseCase;
  late MockProvisionWalletUseCase mockProvisionWalletUseCase;

  setUp(() {
    mockWatchWalletUseCase = MockWatchWalletUseCase();
    mockGetTransactionsUseCase = MockGetTransactionsUseCase();
    mockProvisionWalletUseCase = MockProvisionWalletUseCase();
    cubit = WalletCubit(
      mockWatchWalletUseCase,
      mockGetTransactionsUseCase,
      mockProvisionWalletUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  const tWallet = WalletEntity(
    id: '1',
    balance: 1000.0,
    currency: 'SAR',
    username: 'testuser',
    ownerName: 'Test User',
  );

  final tTransactions = [
    TransactionEntity(
      id: '1',
      amount: 100.0,
      type: TransactionType.credit,
      timestamp: DateTime(2023, 1, 1),
    ),
  ];

  const tError = UnknownError('Test error');

  group('WalletCubit', () {
    test('initial state is BaseState.initial', () {
      expect(cubit.state, const BaseState<WalletState>.initial());
    });

    blocTest<WalletCubit, BaseState<WalletState>>(
      'emits [loading, success] when wallet is received immediately',
      build: () {
        when(() => mockWatchWalletUseCase.call())
            .thenAnswer((_) => Stream.value(const Success(tWallet)));
        when(() => mockGetTransactionsUseCase.watch())
            .thenAnswer((_) => Stream.value(Success(tTransactions)));
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        const BaseState<WalletState>.loading(),
        const BaseState<WalletState>.success(
          WalletState(wallet: tWallet, transactions: []),
        ),
        BaseState<WalletState>.success(
          WalletState(wallet: tWallet, transactions: tTransactions),
        ),
      ],
      verify: (_) {
        verify(() => mockWatchWalletUseCase.call()).called(1);
        verify(() => mockGetTransactionsUseCase.watch()).called(1);
        // provisionWallet should NOT be called if wallet received immediately
        verifyNever(() => mockProvisionWalletUseCase.call());
      },
    );

    blocTest<WalletCubit, BaseState<WalletState>>(
      'emits [loading, error] when wallet stream emits failure',
      build: () {
        when(() => mockWatchWalletUseCase.call())
            .thenAnswer((_) => Stream.value(const Failure(tError)));
        when(() => mockGetTransactionsUseCase.watch())
            .thenAnswer((_) => Stream.empty());
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      wait: const Duration(milliseconds: 100),
      expect: () => const [
        BaseState<WalletState>.loading(),
        BaseState<WalletState>.error(tError),
      ],
      verify: (_) {
        verify(() => mockWatchWalletUseCase.call()).called(1);
      },
    );

    blocTest<WalletCubit, BaseState<WalletState>>(
      'calls provisionWallet after 3s if wallet not received',
      build: () {
        // Wallet stream never emits, simulating missing wallet
        when(() => mockWatchWalletUseCase.call())
            .thenAnswer((_) => Stream.empty());
        when(() => mockGetTransactionsUseCase.watch())
            .thenAnswer((_) => Stream.empty());
        when(() => mockProvisionWalletUseCase.call())
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      wait: const Duration(seconds: 4), // Wait past the 3s provision trigger
      expect: () => const [
        BaseState<WalletState>.loading(),
      ],
      verify: (_) {
        verify(() => mockWatchWalletUseCase.call()).called(1);
        verify(() => mockProvisionWalletUseCase.call()).called(1);
      },
    );

    blocTest<WalletCubit, BaseState<WalletState>>(
      'emits success after provisionWallet creates wallet',
      build: () {
        // First the stream is empty, then after provision it emits wallet
        var callCount = 0;
        when(() => mockWatchWalletUseCase.call()).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            // Initially return stream that emits wallet after delay
            return Stream.fromFuture(
              Future.delayed(
                const Duration(seconds: 4),
                () => const Success(tWallet),
              ),
            );
          }
          return Stream.value(const Success(tWallet));
        });
        when(() => mockGetTransactionsUseCase.watch())
            .thenAnswer((_) => Stream.empty());
        when(() => mockProvisionWalletUseCase.call())
            .thenAnswer((_) async => const Success(null));
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      wait: const Duration(seconds: 5),
      expect: () => [
        const BaseState<WalletState>.loading(),
        const BaseState<WalletState>.success(
          WalletState(wallet: tWallet, transactions: []),
        ),
      ],
      verify: (_) {
        verify(() => mockWatchWalletUseCase.call()).called(1);
        verify(() => mockProvisionWalletUseCase.call()).called(1);
      },
    );
  });
}
