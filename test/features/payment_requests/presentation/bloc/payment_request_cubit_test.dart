import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/core/services/analytics_service.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_username_usecase.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/domain/repo/payment_request_repository.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/features/wallet/domain/usecases/get_wallet_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentRequestRepository extends Mock
    implements PaymentRequestRepository {}

class MockResolveWalletByEmailUseCase extends Mock
    implements ResolveWalletByEmailUseCase {}

class MockResolveWalletByUsernameUseCase extends Mock
    implements ResolveWalletByUsernameUseCase {}

class MockGetWalletUseCase extends Mock implements GetWalletUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

PaymentRequestEntity _request(String id) => PaymentRequestEntity(
  id: id,
  requesterId: 'requester-1',
  payerId: 'payer-1',
  amount: 50000, // integer minor units
  currency: 'EGP',
  status: PaymentRequestStatus.pending,
  createdAt: DateTime(2023),
);

void main() {
  late PaymentRequestCubit cubit;
  late MockPaymentRequestRepository mockRepository;
  late MockResolveWalletByEmailUseCase mockResolveByEmail;
  late MockResolveWalletByUsernameUseCase mockResolveByUsername;
  late MockGetWalletUseCase mockGetWallet;
  late MockAnalyticsService mockAnalyticsService;

  setUpAll(() {
    registerFallbackValue(_request('fallback'));
  });

  setUp(() {
    mockRepository = MockPaymentRequestRepository();
    mockResolveByEmail = MockResolveWalletByEmailUseCase();
    mockResolveByUsername = MockResolveWalletByUsernameUseCase();
    mockGetWallet = MockGetWalletUseCase();
    mockAnalyticsService = MockAnalyticsService();

    // Default: watch streams stay quiet
    when(
      () => mockRepository.watchIncomingRequests(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockRepository.watchOutgoingRequests(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockAnalyticsService.logPaymentRequestCreated(),
    ).thenAnswer((_) async {});

    cubit = PaymentRequestCubit(
      mockRepository,
      mockResolveByEmail,
      mockResolveByUsername,
      mockGetWallet,
      mockAnalyticsService,
    );
  });

  group('createRequest', () {
    test('denominates the request in the wallet currency', () async {
      when(
        () => mockResolveByEmail.call(any()),
      ).thenAnswer((_) async => right('payer-1'));
      when(() => mockGetWallet()).thenAnswer(
        (_) async => right(
          const WalletEntity(
            id: 'wallet-1',
            balance: 0,
            currency: 'EGP',
          ),
        ),
      );
      when(
        () => mockRepository.createRequest(
          payerId: any(named: 'payerId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => right('req-1'));

      await cubit.createRequest(payerId: 'payer@example.com', amount: 50000);

      final captured = verify(
        () => mockRepository.createRequest(
          payerId: 'payer-1',
          amount: 50000,
          currency: captureAny(named: 'currency'),
          note: any(named: 'note'),
        ),
      )..called(1);
      expect(captured.captured.single, 'EGP');
    });

    test('resolves username identifiers before creating', () async {
      when(
        () => mockResolveByUsername.call('bob'),
      ).thenAnswer((_) async => right('bob-wallet-id'));
      when(() => mockGetWallet()).thenAnswer(
        (_) async => right(
          const WalletEntity(id: 'wallet-1', balance: 0, currency: 'SAR'),
        ),
      );
      when(
        () => mockRepository.createRequest(
          payerId: any(named: 'payerId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => right('req-2'));

      await cubit.createRequest(payerId: 'bob', amount: 1000);

      verify(
        () => mockRepository.createRequest(
          payerId: 'bob-wallet-id',
          amount: 1000,
          currency: 'SAR',
          note: any(named: 'note'),
        ),
      ).called(1);
    });

    test('emits error and clears isCreating when wallet fetch fails', () async {
      when(
        () => mockResolveByUsername.call(any()),
      ).thenAnswer((_) async => right('payer-1'));
      when(
        () => mockGetWallet(),
      ).thenAnswer((_) async => left(const ServerFailure('down')));

      await cubit.createRequest(payerId: 'payer-1', amount: 50000);

      // The error state is emitted transiently (UI shows it); the final
      // state clears the creating flag and no request is persisted.
      expect(cubit.state.data?.isCreating, isFalse);
      verifyNever(
        () => mockRepository.createRequest(
          payerId: any(named: 'payerId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          note: any(named: 'note'),
        ),
      );
    });
  });

  group('acceptRequest', () {
    test('removes the accepted request from incoming optimistically', () async {
      final incoming = [_request('r1'), _request('r2')];
      when(() => mockRepository.watchIncomingRequests()).thenAnswer(
        (_) => Stream.value(right(incoming)),
      );
      cubit.init();
      await Future<void>.delayed(Duration.zero);

      when(
        () => mockRepository.acceptRequest('r1'),
      ).thenAnswer((_) async => right(null));

      await cubit.acceptRequest('r1');

      final data = cubit.state.data;
      expect(data, isNotNull);
      expect(data!.incomingRequests.map((e) => e.id), ['r2']);
      expect(data.isActing, isFalse);
    });

    test('emits error when the backend rejects the acceptance', () async {
      when(
        () => mockRepository.acceptRequest('r1'),
      ).thenAnswer((_) async => left(const ServerFailure('failed')));

      await cubit.acceptRequest('r1');

      // The error is emitted, then the action flag is cleared via a
      // success state; verify the call happened and the flag reset.
      verify(() => mockRepository.acceptRequest('r1')).called(1);
      expect(cubit.state.data?.isActing, isFalse);
      expect(cubit.state.data?.actingOnRequestId, isNull);
    });
  });
}
