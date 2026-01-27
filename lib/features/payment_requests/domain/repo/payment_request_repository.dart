import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';

abstract class PaymentRequestRepository {
  Future<Result<String>> createRequest(
      {required String payerId,
      required double amount,
      required String currency,
      String? note});

  Stream<Result<List<PaymentRequestEntity>>> watchIncomingRequests();
  Stream<Result<List<PaymentRequestEntity>>> watchOutgoingRequests();

  Future<Result<void>> acceptRequest(String requestId);
  Future<Result<void>> declineRequest(String requestId);
}
