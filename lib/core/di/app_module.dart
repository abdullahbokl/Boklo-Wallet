import 'package:boklo/core/config/app_config.dart';
import 'package:boklo/core/network/interceptors/auth_interceptor.dart';
import 'package:boklo/core/network/interceptors/logger_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

@module
abstract class AppModule {
  @lazySingleton
  Dio dio(
    AppConfig config,
    AuthInterceptor authInterceptor,
    LoggerInterceptor loggerInterceptor,
  ) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.addAll([
      authInterceptor,
      loggerInterceptor,
    ]);

    return dio;
  }

  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage => const FlutterSecureStorage();

  @lazySingleton
  InternetConnection get internetConnection => InternetConnection();

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
}
