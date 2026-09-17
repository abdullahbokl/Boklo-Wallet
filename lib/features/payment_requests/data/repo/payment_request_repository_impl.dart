import 'dart:async';
import 'dart:developer';

import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/payment_requests/data/datasources/payment_request_remote_data_source.dart';
import 'package:boklo/features/payment_requests/data/model/payment_request_model.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/domain/repo/payment_request_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PaymentRequestRepository)
class PaymentRequestRepositoryImpl implements PaymentRequestRepository {
  PaymentRequestRepositoryImpl(this._remoteDataSource);
  final PaymentRequestRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, String>> createRequest({
    required String payerId,
    required int amount,
    required String currency,
    String? note,
  }) async {
    try {
      final id = await _remoteDataSource.createRequest({
        'payerId': payerId,
        'amount': amount,
        'currency': currency,
        'note': note,
      });
      return Right(id);
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<PaymentRequestEntity>>> watchIncomingRequests() {
    return _remoteDataSource.watchIncomingRequests().transform(
      StreamTransformer<
        List<PaymentRequestModel>,
        Either<Failure, List<PaymentRequestEntity>>
      >.fromHandlers(
        handleData: (data, sink) {
          try {
            log(
              '[REPO DEBUG] watchIncomingRequests received ${data.length}  '
              'items',
            );
            sink.add(Right(data.map((e) => e.toEntity()).toList()));
          } on Object catch (e) {
            log('[REPO ERROR] watchIncomingRequests transform error: $e');
            sink.add(Left(UnknownFailure(e.toString())));
          }
        },
        handleError: (error, stack, sink) {
          log('[REPO ERROR] watchIncomingRequests stream error: $error');
          sink.add(Left(UnknownFailure(error.toString())));
        },
      ),
    );
  }

  @override
  Stream<Either<Failure, List<PaymentRequestEntity>>> watchOutgoingRequests() {
    return _remoteDataSource.watchOutgoingRequests().transform(
      StreamTransformer<
        List<PaymentRequestModel>,
        Either<Failure, List<PaymentRequestEntity>>
      >.fromHandlers(
        handleData: (data, sink) {
          try {
            log(
              '[REPO DEBUG] watchOutgoingRequests received '
              '${data.length} items',
            );
            sink.add(Right(data.map((e) => e.toEntity()).toList()));
          } on Object catch (e) {
            log('[REPO ERROR] watchOutgoingRequests transform error: $e');
            sink.add(Left(UnknownFailure(e.toString())));
          }
        },
        handleError: (error, stack, sink) {
          log('[REPO ERROR] watchOutgoingRequests stream error: $error');
          sink.add(Left(UnknownFailure(error.toString())));
        },
      ),
    );
  }

  @override
  Future<Either<Failure, void>> acceptRequest(String requestId) async {
    try {
      log('[REPO DEBUG] acceptRequest called for: $requestId');
      await _remoteDataSource.acceptRequest(requestId);
      log('[REPO DEBUG] acceptRequest SUCCESS');
      return const Right(null);
    } on Object catch (e, stack) {
      log('[REPO ERROR] acceptRequest failed: $e');
      log('[REPO ERROR] Stack: $stack');
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineRequest(String requestId) async {
    try {
      log('[REPO DEBUG] declineRequest called for: $requestId');
      await _remoteDataSource.declineRequest(requestId);
      log('[REPO DEBUG] declineRequest SUCCESS');
      return const Right(null);
    } on Object catch (e, stack) {
      log('[REPO ERROR] declineRequest failed: $e');
      log('[REPO ERROR] Stack: $stack');
      return Left(UnknownFailure(e.toString()));
    }
  }
}
