import 'package:bloc_test/bloc_test.dart';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/config/feature_flags.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/request_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/observe_transfer_status_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_username_usecase.dart';

class MockCreateTransferUseCase extends Mock implements CreateTransferUseCase {}

class MockRequestTransferUseCase extends Mock
    implements RequestTransferUseCase {}

class MockResolveWalletByEmailUseCase extends Mock
    implements ResolveWalletByEmailUseCase {}

class MockResolveWalletByUsernameUseCase extends Mock
    implements ResolveWalletByUsernameUseCase {}

class MockObserveTransferStatusUseCase extends Mock
    implements ObserveTransferStatusUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockFeatureFlags extends Mock implements FeatureFlags {}

void main() {
  late TransferCubit cubit;
  late MockCreateTransferUseCase mockCreateTransferUseCase;
  late MockRequestTransferUseCase mockRequestTransferUseCase;
  late MockResolveWalletByEmailUseCase mockResolveWalletByEmailUseCase;
  late MockResolveWalletByUsernameUseCase mockResolveWalletByUsernameUseCase;
  late MockObserveTransferStatusUseCase mockObserveTransferStatusUseCase;
  late MockAnalyticsService mockAnalyticsService;
  late MockFeatureFlags mockFeatureFlags;

  setUp(() {
    mockCreateTransferUseCase = MockCreateTransferUseCase();
    mockRequestTransferUseCase = MockRequestTransferUseCase();
    mockResolveWalletByEmailUseCase = MockResolveWalletByEmailUseCase();
    mockResolveWalletByUsernameUseCase = MockResolveWalletByUsernameUseCase();
    mockObserveTransferStatusUseCase = MockObserveTransferStatusUseCase();
    mockAnalyticsService = MockAnalyticsService();
    mockFeatureFlags = MockFeatureFlags();

    when(() => mockAnalyticsService.logTransferFailure(
        reason: any(named: 'reason'))).thenAnswer((_) async {});

    registerFallbackValue(
      TransferEntity(
        id: 'fallback',
        fromWalletId: '1',
        toWalletId: '2',
        amount: 10,
        currency: 'SAR',
        status: TransferStatus.pending,
        createdAt: DateTime(2023),
      ),
    );

    cubit = TransferCubit(
      mockCreateTransferUseCase,
      mockRequestTransferUseCase,
      mockResolveWalletByEmailUseCase,
      mockResolveWalletByUsernameUseCase,
      mockObserveTransferStatusUseCase,
      mockAnalyticsService,
      mockFeatureFlags,
    );
  });

  const tFromId = 'wallet1';
  // Use a 28-char ID to bypass username resolution logic and treat as Direct Wallet ID
  const tToId = '1234567890123456789012345678';
  const tAmount = 100.0;
  const tCurrency = 'SAR';

  group('createTransfer', () {
    test(
        'should call CreateTransferUseCase manually when feature flag is DISABLED',
        () async {
      // Arrange
      when(() => mockFeatureFlags.backendAuthoritativeTransfers)
          .thenReturn(false);
      when(() => mockCreateTransferUseCase.call(any()))
          .thenAnswer((_) async => const Success(null));
      when(() => mockAnalyticsService.logTransferInitiated(
          amount: any(named: 'amount'),
          currency: any(named: 'currency'))).thenAnswer((_) async {});

      // Act
      await cubit.createTransfer(
        fromWalletId: tFromId,
        recipient: tToId,
        amount: tAmount,
        currency: tCurrency,
      );

      // Assert
      verify(() =>
              mockCreateTransferUseCase.call(any(that: isA<TransferEntity>())))
          .called(1);
      verifyNever(() => mockRequestTransferUseCase.call(
            fromWalletId: any(named: 'fromWalletId'),
            toWalletId: any(named: 'toWalletId'),
            amount: any(named: 'amount'),
          ));
    });

    test(
        'should call RequestTransferUseCase then CreateTransferUseCase when feature flag is ENABLED',
        () async {
      // Arrange
      when(() => mockFeatureFlags.backendAuthoritativeTransfers)
          .thenReturn(true);

      final tTransfer = TransferEntity(
        id: 'new_id',
        fromWalletId: tFromId,
        toWalletId: tToId,
        amount: tAmount,
        currency: tCurrency,
        status: TransferStatus.pending,
        createdAt: DateTime.now(),
      );

      when(() => mockRequestTransferUseCase.call(
            fromWalletId: any(named: 'fromWalletId'),
            toWalletId: any(named: 'toWalletId'),
            amount: any(named: 'amount'),
          )).thenAnswer((_) async => Success(tTransfer));

      when(() => mockCreateTransferUseCase.call(any()))
          .thenAnswer((_) async => const Success(null));

      when(() => mockAnalyticsService.logTransferInitiated(
          amount: any(named: 'amount'),
          currency: any(named: 'currency'))).thenAnswer((_) async {});

      // Mock Observation Stream
      when(() => mockObserveTransferStatusUseCase.call(any())).thenAnswer(
        (_) => Stream.fromIterable([
          TransferEntity(
            id: 'new_id',
            fromWalletId: tFromId,
            toWalletId: tToId,
            amount: tAmount,
            currency: tCurrency,
            status: TransferStatus.pending,
            createdAt: DateTime.now(),
          ),
          TransferEntity(
            id: 'new_id',
            fromWalletId: tFromId,
            toWalletId: tToId,
            amount: tAmount,
            currency: tCurrency,
            status: TransferStatus.completed,
            createdAt: DateTime.now(),
          ),
        ]),
      );

      // Act
      await cubit.createTransfer(
        fromWalletId: tFromId,
        recipient: tToId, // recipient IS the wallet ID
        amount: tAmount,
        currency: tCurrency,
      );

      // Assert
      verify(() => mockRequestTransferUseCase.call(
            fromWalletId: tFromId,
            toWalletId: tToId,
            amount: tAmount,
          )).called(1);

      verify(() => mockCreateTransferUseCase.call(tTransfer)).called(1);

      // Verify we waited for completion
      verify(() => mockObserveTransferStatusUseCase.call('new_id')).called(1);
    });
  });
}
