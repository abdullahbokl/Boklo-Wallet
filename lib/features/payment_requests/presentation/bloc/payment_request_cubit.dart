import 'dart:async';

import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/payment_requests/domain/repo/payment_request_repository.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class PaymentRequestCubit extends BaseCubit<PaymentRequestState> {
  final PaymentRequestRepository _repository;
  StreamSubscription<dynamic>? _incomingSub;
  StreamSubscription<dynamic>? _outgoingSub;

  PaymentRequestCubit(this._repository) : super(const BaseState.initial());

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
        print('[CUBIT ERROR] watchIncomingRequests: $error');
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
        print('[CUBIT ERROR] watchOutgoingRequests: $error');
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

    final result = await _repository.createRequest(
        payerId: payerId, amount: amount, currency: currency, note: note);

    result.fold((error) {
      emitError(error);
      // Revert loading state? Or just show error and keep state?
      // Usually emitError shows snackbar/dialog.
      emitSuccess(currentState.copyWith(isCreating: false));
    }, (id) {
      emitSuccess(currentState.copyWith(isCreating: false));
      // Navigate back or show success handled by UI listener
    });
  }

  Future<void> acceptRequest(String requestId) async {
    print('[DEBUG] acceptRequest called for requestId: $requestId');
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(currentState.copyWith(isActing: true));

    final result = await _repository.acceptRequest(requestId);

    result.fold((error) {
      print('[ERROR] acceptRequest failed: ${error.message}');
      emitError(error);
      emitSuccess(currentState.copyWith(isActing: false));
    }, (_) {
      print('[DEBUG] acceptRequest success');
      emitSuccess(currentState.copyWith(isActing: false));
    });
  }

  Future<void> declineRequest(String requestId) async {
    print('[DEBUG] declineRequest called for requestId: $requestId');
    final currentState = state.data ?? const PaymentRequestState();
    emitSuccess(currentState.copyWith(isActing: true));

    final result = await _repository.declineRequest(requestId);

    result.fold((error) {
      print('[ERROR] declineRequest failed: ${error.message}');
      emitError(error);
      emitSuccess(currentState.copyWith(isActing: false));
    }, (_) {
      print('[DEBUG] declineRequest success');
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
