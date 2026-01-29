import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/payment_requests/domain/repo/payment_request_repository.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class PaymentRequestCubit extends BaseCubit<PaymentRequestState> {
  final PaymentRequestRepository _repository;
  final ResolveWalletByEmailUseCase _resolveWalletByEmailUseCase;
  StreamSubscription<dynamic>? _incomingSub;
  StreamSubscription<dynamic>? _outgoingSub;

  PaymentRequestCubit(
    this._repository,
    this._resolveWalletByEmailUseCase,
  ) : super(const BaseState.initial());

  void init() {
    emitLoading();
    _watchIncoming();
    _watchOutgoing();
  }

  void _watchIncoming() {
    _incomingSub?.cancel();
    _incomingSub = _repository.watchIncomingRequests().listen(
      (result) {
        result.fold((error) => emitError(error), (data) {
          // Merge with current state or create new success
          final currentState = state.data ?? const PaymentRequestState();
          emitSuccess(currentState.copyWith(incomingRequests: data));
        });
      },
      onError: (Object error) {
        // Log error
      },
    );
  }

  void _watchOutgoing() {
    _outgoingSub?.cancel();
    _outgoingSub = _repository.watchOutgoingRequests().listen(
      (result) {
        result.fold((error) => emitError(error), (data) {
          final currentState = state.data ?? const PaymentRequestState();
          emitSuccess(currentState.copyWith(outgoingRequests: data));
        });
      },
      onError: (Object error) {
        // Log error
      },
    );
  }

  Future<void> createRequest({
    required String payerId,
    required double amount,
    required String currency,
    String? note,
  }) async {
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(currentState.copyWith(isCreating: true));

    var targetPayerId = payerId.trim();

    // 1. Resolve Email if needed
    if (targetPayerId.contains('@')) {
      final resolution = await _resolveWalletByEmailUseCase(targetPayerId);
      final error = resolution.fold((l) => l, (r) => null);
      if (error != null) {
        emitError(error);
        emitSuccess(currentState.copyWith(isCreating: false));
        return;
      }
      targetPayerId = resolution.fold((l) => '', (r) => r);
    }

    // 2. Create Request
    final result = await _repository.createRequest(
        payerId: targetPayerId, amount: amount, currency: currency, note: note);

    result.fold((error) {
      emitError(error);
      emitSuccess(currentState.copyWith(isCreating: false));
    }, (id) {
      emitSuccess(currentState.copyWith(isCreating: false));
    });
  }

  Future<void> acceptRequest(String requestId) async {
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(currentState.copyWith(isActing: true));

    final result = await _repository.acceptRequest(requestId);

    result.fold((error) {
      emitError(error);
      emitSuccess(currentState.copyWith(isActing: false));
    }, (_) {
      emitSuccess(currentState.copyWith(isActing: false));
    });
  }

  Future<void> declineRequest(String requestId) async {
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(currentState.copyWith(isActing: true));

    final result = await _repository.declineRequest(requestId);

    result.fold((error) {
      emitError(error);
      emitSuccess(currentState.copyWith(isActing: false));
    }, (_) {
      emitSuccess(currentState.copyWith(isActing: false));
    });
  }

  @override
  Future<void> close() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    return super.close();
  }
}
