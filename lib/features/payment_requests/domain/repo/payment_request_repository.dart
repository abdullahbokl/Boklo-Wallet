import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class PaymentRequestRepository {
  Future<Either<Failure, String>> createRequest(
      {required String payerId,
      required double amount,
      required String currency,
      String? note,});

  Stream<Either<Failure, List<PaymentRequestEntity>>> watchIncomingRequests();
  Stream<Either<Failure, List<PaymentRequestEntity>>> watchOutgoingRequests();

  Future<Either<Failure, void>> acceptRequest(String requestId);
  Future<Either<Failure, void>> declineRequest(String requestId);
}
