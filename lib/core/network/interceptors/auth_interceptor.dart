import 'package:boklo/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthInterceptor extends Interceptor {

  AuthInterceptor(this._storageService);
  // ignore: unused_field
  final SecureStorageService _storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // TODO(dev): getToken from storage
    // final token = await _storageService.getToken();
    const token = 'dummy_token';
    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
