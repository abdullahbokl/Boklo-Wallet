import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request_entity.freezed.dart';

enum PaymentRequestStatus {
  pending,
  accepted,
  declined,
  invalid;

  String get label => name.toUpperCase();
}

@freezed
class PaymentRequestEntity with _$PaymentRequestEntity {
  const factory PaymentRequestEntity({
    required String id,
    required String requesterId,
    required String payerId,
    required double amount,
    required String currency,
    required PaymentRequestStatus status, required DateTime createdAt, String? note,
    DateTime? acceptedAt,
    DateTime? declinedAt,
  }) = _PaymentRequestEntity;
}
