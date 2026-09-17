import 'package:boklo/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for filing transaction disputes (captured for ops review).
/// Single-method contract is intentional (repository boundary).
// ignore: one_member_abstracts
abstract class DisputeRepository {
  Future<Either<Failure, void>> submitDispute({
    required String transactionId,
    required String walletId,
    required int amount,
    required String currency,
    required String reason,
  });
}
