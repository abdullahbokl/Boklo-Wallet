import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request_state.freezed.dart';

@freezed
class PaymentRequestState with _$PaymentRequestState {
  const factory PaymentRequestState({
    @Default([]) List<PaymentRequestEntity> incomingRequests,
    @Default([]) List<PaymentRequestEntity> outgoingRequests,
    @Default(false) bool isCreating,
    @Default(false) bool isActing, // Accepting/Declining
    String? actingOnRequestId, // Track which request is being processed
  }) = _PaymentRequestState;
}
