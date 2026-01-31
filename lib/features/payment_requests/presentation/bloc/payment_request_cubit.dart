import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_username_usecase.dart';
import 'package:boklo/features/payment_requests/domain/repo/payment_request_repository.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class PaymentRequestCubit extends BaseCubit<PaymentRequestState> {
  PaymentRequestCubit(
    this._repository,
    this._resolveWalletByEmailUseCase,
    this._resolveWalletByUsernameUseCase,
  ) : super(const BaseState.initial());

  final PaymentRequestRepository _repository;
  final ResolveWalletByEmailUseCase _resolveWalletByEmailUseCase;
  final ResolveWalletByUsernameUseCase _resolveWalletByUsernameUseCase;
  StreamSubscription<dynamic>? _incomingSub;
  StreamSubscription<dynamic>? _outgoingSub;

  void init() {
    emitLoading();
    _watchIncoming();
    _watchOutgoing();
  }

  void _watchIncoming() {
    _incomingSub?.cancel();
    _incomingSub = _repository.watchIncomingRequests().listen(
      (result) {
        result.fold(
          emitError,
          (data) {
            // Merge with current state or create new success
            final currentState = state.data ?? const PaymentRequestState();
            emitSuccess(currentState.copyWith(incomingRequests: data));
          },
        );
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
        result.fold(
          emitError,
          (data) {
            final currentState = state.data ?? const PaymentRequestState();
            emitSuccess(currentState.copyWith(outgoingRequests: data));
          },
        );
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

    // 1. Resolve Identifier (Email or Alias)
    if (targetPayerId.contains('@')) {
      final resolution = await _resolveWalletByEmailUseCase(targetPayerId);
      final error = resolution.fold((l) => l, (r) => null);
      if (error != null) {
        emitError(error);
        emitSuccess(currentState.copyWith(isCreating: false));
        return;
      }
      targetPayerId = resolution.fold((l) => '', (r) => r);
    } else {
      // Try to resolve as username
      final resolution = await _resolveWalletByUsernameUseCase(targetPayerId);
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
      payerId: targetPayerId,
      amount: amount,
      currency: currency,
      note: note,
    );

    result.fold(
      emitError,
      (id) {
        emitSuccess(currentState.copyWith(isCreating: false));
      },
    );
  }

  Future<void> acceptRequest(String requestId) async {
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(
      currentState.copyWith(
        isActing: true,
        actingOnRequestId: requestId,
      ),
    );

    final result = await _repository.acceptRequest(requestId);

    result.fold(
      (error) {
        emitError(error);
        emitSuccess(
          currentState.copyWith(
            isActing: false,
            actingOnRequestId: null,
          ),
        );
      },
      (_) {
        // Optimistic update: remove the request from the list immediately
        final updatedIncoming = currentState.incomingRequests
            .where((req) => req.id != requestId)
            .toList();
        emitSuccess(
          currentState.copyWith(
            isActing: false,
            actingOnRequestId: null,
            incomingRequests: updatedIncoming,
          ),
        );
      },
    );
  }

  Future<void> declineRequest(String requestId) async {
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(
      currentState.copyWith(
        isActing: true,
        actingOnRequestId: requestId,
      ),
    );

    final result = await _repository.declineRequest(requestId);

    result.fold(
      (error) {
        emitError(error);
        emitSuccess(
          currentState.copyWith(
            isActing: false,
            actingOnRequestId: null,
          ),
        );
      },
      (_) {
        // Optimistic update: remove the request from the list immediately
        final updatedIncoming = currentState.incomingRequests
            .where((req) => req.id != requestId)
            .toList();
        emitSuccess(
          currentState.copyWith(
            isActing: false,
            actingOnRequestId: null,
            incomingRequests: updatedIncoming,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    unawaited(_incomingSub?.cancel());
    unawaited(_outgoingSub?.cancel());
    return super.close();
  }
}
