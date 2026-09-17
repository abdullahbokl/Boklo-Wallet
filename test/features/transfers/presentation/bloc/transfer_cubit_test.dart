import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/domain/usecases/create_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/observe_transfer_status_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/request_transfer_usecase.dart';
import 'package:boklo/features/transfers/domain/usecases/resolve_recipient_usecase.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateTransferUseCase extends Mock implements CreateTransferUseCase {}

class MockRequestTransferUseCase extends Mock
    implements RequestTransferUseCase {}

class MockResolveRecipientUseCase extends Mock
    implements ResolveRecipientUseCase {}

class MockObserveTransferStatusUseCase extends Mock
    implements ObserveTransferStatusUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

TransferEntity _transfer({
  required String id,
  required TransferStatus status,
}) {
  return TransferEntity(
    id: id,
    fromWalletId: 'wallet1',
    toWalletId: '1234567890123456789012345678',
    amount: 100,
    currency: 'SAR',
    status: status,
    createdAt: DateTime(2023),
  );
}

void main() {
  late TransferCubit cubit;
  late MockCreateTransferUseCase mockCreateTransferUseCase;
  late MockRequestTransferUseCase mockRequestTransferUseCase;
  late MockResolveRecipientUseCase mockResolveRecipientUseCase;
  late MockObserveTransferStatusUseCase mockObserveTransferStatusUseCase;
  late MockAnalyticsService mockAnalyticsService;

  setUp(() {
    mockCreateTransferUseCase = MockCreateTransferUseCase();
    mockRequestTransferUseCase = MockRequestTransferUseCase();
    mockResolveRecipientUseCase = MockResolveRecipientUseCase();
    mockObserveTransferStatusUseCase = MockObserveTransferStatusUseCase();
    mockAnalyticsService = MockAnalyticsService();

    when(
      () => mockAnalyticsService.logTransferFailure(
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async {});

    // Default success for recipient resolution (assumes direct wallet ID by
    // default)
    when(() => mockResolveRecipientUseCase.call(any())).thenAnswer((
      invocation,
    ) async {
      final recipient = invocation.positionalArguments.first as String;
      return right(recipient);
    });

    registerFallbackValue(
      _transfer(id: 'fallback', status: TransferStatus.pending),
    );

    cubit = TransferCubit(
      mockCreateTransferUseCase,
      mockRequestTransferUseCase,
      mockResolveRecipientUseCase,
      mockObserveTransferStatusUseCase,
      mockAnalyticsService,
    );
  });

  const tFromId = 'wallet1';
  // Use a 28-char ID to bypass username resolution logic and treat as a
  // direct wallet ID.
  const tToId = '1234567890123456789012345678';
  const tAmount = 100.0;
  const tCurrency = 'SAR';

  group('createTransfer', () {
    test(
      'requests transfer, persists it, then waits for backend completion',
      () async {
        // Arrange
        final transfer = _transfer(
          id: 'new_id',
          status: TransferStatus.pending,
        );

        when(
          () => mockRequestTransferUseCase.call(
            fromWalletId: any(named: 'fromWalletId'),
            toWalletId: any(named: 'toWalletId'),
            amount: any(named: 'amount'),
          ),
        ).thenAnswer((_) async => right(transfer));

        when(
          () => mockCreateTransferUseCase.call(any()),
        ).thenAnswer((_) async => right(null));

        when(
          () => mockAnalyticsService.logTransferInitiated(
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
          ),
        ).thenAnswer((_) async {});

        when(() => mockObserveTransferStatusUseCase.call(any())).thenAnswer(
          (_) => Stream.fromIterable([
            right(_transfer(id: 'new_id', status: TransferStatus.pending)),
            right(_transfer(id: 'new_id', status: TransferStatus.completed)),
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
        verify(
          () => mockRequestTransferUseCase.call(
            fromWalletId: tFromId,
            toWalletId: tToId,
            amount: tAmount,
          ),
        ).called(1);

        verify(() => mockCreateTransferUseCase.call(transfer)).called(1);

        // Verify we waited for completion
        verify(() => mockObserveTransferStatusUseCase.call('new_id')).called(1);
        verifyNever(
          () => mockAnalyticsService.logTransferFailure(
            reason: any(named: 'reason'),
          ),
        );
      },
    );

    test('emits error and skips persistence when request fails', () async {
      // Arrange
      when(
        () => mockRequestTransferUseCase.call(
          fromWalletId: any(named: 'fromWalletId'),
          toWalletId: any(named: 'toWalletId'),
          amount: any(named: 'amount'),
        ),
      ).thenAnswer((_) async => left(const ValidationFailure('insufficient')));

      // Act
      await cubit.createTransfer(
        fromWalletId: tFromId,
        recipient: tToId,
        amount: tAmount,
        currency: tCurrency,
      );

      // Assert
      verifyNever(() => mockCreateTransferUseCase.call(any()));
      verifyNever(() => mockObserveTransferStatusUseCase.call(any()));
      verify(
        () => mockAnalyticsService.logTransferFailure(reason: 'insufficient'),
      ).called(1);
    });
  });
}
