import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/payment_requests/data/datasources/payment_request_remote_data_source.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/domain/repo/payment_request_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:boklo/features/payment_requests/data/model/payment_request_model.dart';

@LazySingleton(as: PaymentRequestRepository)
class PaymentRequestRepositoryImpl implements PaymentRequestRepository {
  final PaymentRequestRemoteDataSource _remoteDataSource;

  PaymentRequestRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<String>> createRequest({
    required String payerId,
    required double amount,
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
      return Success(id);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Stream<Result<List<PaymentRequestEntity>>> watchIncomingRequests() {
    return _remoteDataSource.watchIncomingRequests().transform(
          StreamTransformer<List<PaymentRequestModel>,
              Result<List<PaymentRequestEntity>>>.fromHandlers(
            handleData: (data, sink) {
              try {
                print(
                    '[REPO DEBUG] watchIncomingRequests received ${data.length} items');
                sink.add(Success(data.map((e) => e.toEntity()).toList()));
              } catch (e) {
                print('[REPO ERROR] watchIncomingRequests transform error: $e');
                sink.add(Failure(UnknownError(e.toString())));
              }
            },
            handleError: (error, stack, sink) {
              print('[REPO ERROR] watchIncomingRequests stream error: $error');
              sink.add(Failure(UnknownError(error.toString())));
            },
          ),
        );
  }

  @override
  Stream<Result<List<PaymentRequestEntity>>> watchOutgoingRequests() {
    return _remoteDataSource.watchOutgoingRequests().transform(
          StreamTransformer<List<PaymentRequestModel>,
              Result<List<PaymentRequestEntity>>>.fromHandlers(
            handleData: (data, sink) {
              try {
                print(
                    '[REPO DEBUG] watchOutgoingRequests received ${data.length} items');
                sink.add(Success(data.map((e) => e.toEntity()).toList()));
              } catch (e) {
                print('[REPO ERROR] watchOutgoingRequests transform error: $e');
                sink.add(Failure(UnknownError(e.toString())));
              }
            },
            handleError: (error, stack, sink) {
              print('[REPO ERROR] watchOutgoingRequests stream error: $error');
              sink.add(Failure(UnknownError(error.toString())));
            },
          ),
        );
  }

  @override
  Future<Result<void>> acceptRequest(String requestId) async {
    try {
      print('[REPO DEBUG] acceptRequest called for: $requestId');
      await _remoteDataSource.acceptRequest(requestId);
      print('[REPO DEBUG] acceptRequest SUCCESS');
      return const Success(null);
    } catch (e, stack) {
      print('[REPO ERROR] acceptRequest failed: $e');
      print('[REPO ERROR] Stack: $stack');
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> declineRequest(String requestId) async {
    try {
      print('[REPO DEBUG] declineRequest called for: $requestId');
      await _remoteDataSource.declineRequest(requestId);
      print('[REPO DEBUG] declineRequest SUCCESS');
      return const Success(null);
    } catch (e, stack) {
      print('[REPO ERROR] declineRequest failed: $e');
      print('[REPO ERROR] Stack: $stack');
      return Failure(UnknownError(e.toString()));
    }
  }
}
