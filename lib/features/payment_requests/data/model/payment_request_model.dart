import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_request_model.g.dart';
part 'payment_request_model.freezed.dart';

@freezed
class PaymentRequestModel with _$PaymentRequestModel {
  // Ignore extra fields for firestore compatibility if needed, using generic json logic
  const factory PaymentRequestModel({
    required String id,
    required String requesterId,
    required String payerId,
    required double amount,
    required String currency,
    String? note,
    required String status, // String from Firestore, mapped to Enum in toEntity
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
    @JsonKey(
        fromJson: _timestampNullableFromJson, toJson: _timestampNullableToJson)
    DateTime? acceptedAt,
    @JsonKey(
        fromJson: _timestampNullableFromJson, toJson: _timestampNullableToJson)
    DateTime? declinedAt,
  }) = _PaymentRequestModel;

  factory PaymentRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestModelFromJson(json);

  factory PaymentRequestModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return PaymentRequestModel.fromJson(data);
  }
}

DateTime _timestampFromJson(Object json) {
  if (json is Timestamp) {
    return json.toDate();
  } else if (json is String) {
    return DateTime.parse(json);
  }
  return DateTime.now(); // Fallback
}

Object _timestampToJson(DateTime date) => Timestamp.fromDate(date);

DateTime? _timestampNullableFromJson(Object? json) {
  if (json == null) return null;
  if (json is Timestamp) {
    return json.toDate();
  } else if (json is String) {
    return DateTime.parse(json);
  }
  return null;
}

Object? _timestampNullableToJson(DateTime? date) =>
    date == null ? null : Timestamp.fromDate(date);

extension PaymentRequestModelX on PaymentRequestModel {
  PaymentRequestEntity toEntity() {
    return PaymentRequestEntity(
      id: id,
      requesterId: requesterId,
      payerId: payerId,
      amount: amount,
      currency: currency,
      note: note,
      status: PaymentRequestStatus.values.firstWhere(
          (e) => e.name.toUpperCase() == status.toUpperCase(),
          orElse: () => PaymentRequestStatus.invalid),
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      declinedAt: declinedAt,
    );
  }
}
