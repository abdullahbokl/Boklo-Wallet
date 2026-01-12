import 'package:bloc_test/bloc_test.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/usecases/get_transactions_usecase.dart';
import 'package:boklo/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWalletUseCase extends Mock implements GetWalletUseCase {}

class MockGetTransactionsUseCase extends Mock
    implements GetTransactionsUseCase {}

void main() {
  late WalletCubit cubit;
  late MockGetWalletUseCase mockGetWalletUseCase;
  late MockGetTransactionsUseCase mockGetTransactionsUseCase;

  setUp(() {
    mockGetWalletUseCase = MockGetWalletUseCase();
    mockGetTransactionsUseCase = MockGetTransactionsUseCase();
    cubit = WalletCubit(
      mockGetWalletUseCase,
      mockGetTransactionsUseCase,
    );
  });

  const tWallet = WalletEntity(
    id: '1',
    balance: 1000.0,
    currency: 'USD',
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
      'emits [loading, success] when data is fetched successfully',
      build: () {
        when(() => mockGetWalletUseCase.call())
            .thenAnswer((_) async => const Success(tWallet));
        when(() => mockGetTransactionsUseCase.watch())
            .thenAnswer((_) => Stream.value(Success(tTransactions)));
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      expect: () => [
        const BaseState<WalletState>.loading(),
        BaseState<WalletState>.success(
          WalletState(wallet: tWallet, transactions: tTransactions),
        ),
      ],
      verify: (_) {
        verify(() => mockGetWalletUseCase.call()).called(1);
        verify(() => mockGetTransactionsUseCase.watch()).called(1);
      },
    );

    blocTest<WalletCubit, BaseState<WalletState>>(
      'emits [loading, error] when fetch wallet fails',
      build: () {
        when(() => mockGetWalletUseCase.call())
            .thenAnswer((_) async => const Failure(tError));
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      expect: () => const [
        BaseState<WalletState>.loading(),
        BaseState<WalletState>.error(tError),
      ],
      verify: (_) {
        verify(() => mockGetWalletUseCase.call()).called(1);
        verifyNever(() => mockGetTransactionsUseCase.watch());
      },
    );

    blocTest<WalletCubit, BaseState<WalletState>>(
      'emits [loading, error] when fetch transactions fails',
      build: () {
        when(() => mockGetWalletUseCase.call())
            .thenAnswer((_) async => const Success(tWallet));
        when(() => mockGetTransactionsUseCase.watch())
            .thenAnswer((_) => Stream.value(const Failure(tError)));
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      expect: () => const [
        BaseState<WalletState>.loading(),
        BaseState<WalletState>.error(tError),
      ],
      verify: (_) {
        verify(() => mockGetWalletUseCase.call()).called(1);
        verify(() => mockGetTransactionsUseCase.watch()).called(1);
      },
    );
  });
}
