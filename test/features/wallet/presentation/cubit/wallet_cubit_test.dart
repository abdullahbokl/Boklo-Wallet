import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/base/result.dart';
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

  final tWallet = WalletEntity(
    id: 'w1',
    currency: 'USD',
    balance: 100.0,
    ownerName: 'Test User',
    alias: 'tester',
  );

  final tTransactions = [
    TransactionEntity(
      id: 't1',
      amount: 50.0,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      timestamp: DateTime.now(),
    ),
  ];

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

  tearDown(() => cubit.close());

  group('WalletCubit', () {
    test('initial state is BaseState.initial', () {
      expect(cubit.state, const BaseState<WalletState>.initial());
    });

    blocTest<WalletCubit, BaseState<WalletState>>(
      'emits [loading, success(empty tx), success(with tx)] when data is received',
      build: () {
        when(() => mockWatchWalletUseCase()).thenAnswer(
          (_) => Stream.value(Success(tWallet)),
        );
        when(() => mockGetTransactionsUseCase.watch()).thenAnswer(
          (_) => Stream.value(Success(tTransactions)),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadWallet(),
      expect: () => [
        const BaseState<WalletState>.loading(),
        // First success: Wallet loaded, transactions empty (initially)
        isA<BaseState<WalletState>>()
            .having((s) => s.data?.wallet, 'wallet', tWallet)
            .having((s) => s.data?.transactions, 'transactions', isEmpty),
        // Second success: Transactions loaded
        isA<BaseState<WalletState>>()
            .having((s) => s.data?.wallet, 'wallet', tWallet)
            .having((s) => s.data?.transactions, 'transactions', tTransactions),
      ],
    );

    blocTest<WalletCubit, BaseState<WalletState>>(
      'filters transactions correctly',
      build: () {
        when(() => mockWatchWalletUseCase()).thenAnswer(
          (_) => Stream.value(Success(tWallet)),
        );
        when(() => mockGetTransactionsUseCase.watch()).thenAnswer(
          (_) => Stream.value(Success(tTransactions)),
        );
        return cubit;
      },
      act: (cubit) async {
        await cubit.loadWallet();
        // Wait for streams to emit
        await Future<void>.delayed(Duration.zero);
        cubit.setFilterType(TransactionType.debit);
      },
      skip: 3, // Skip loading, success(empty), success(full)
      expect: () => [
        isA<BaseState<WalletState>>().having(
          (s) => s.data?.transactions.isEmpty,
          'transactions empty (filtered)',
          true,
        ),
      ],
    );
  });
}
