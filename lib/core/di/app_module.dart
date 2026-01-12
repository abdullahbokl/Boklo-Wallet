import 'package:boklo/core/config/app_config.dart' as app_config;
import 'package:boklo/core/config/feature_flags.dart';
import 'package:boklo/core/network/interceptors/auth_interceptor.dart';
import 'package:boklo/core/network/interceptors/logger_interceptor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

@module
abstract class AppModule {
  @lazySingleton
  Dio dio(
    app_config.AppConfig config,
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

  @lazySingleton
  FirebaseFirestore get firebaseFirestore => FirebaseFirestore.instance;

  @singleton
  @Environment(Environment.dev)
  app_config.AppConfig get devConfig => const app_config.AppConfig(
        environment: app_config.Environment.dev,
        apiBaseUrl: 'https://dev-api.boklo.com',
        firebaseProjectId: 'boklo-dev',
        featureFlags: FeatureFlags(
          enableBiometrics: true,
          enableBetaFeatures: true,
        ),
      );

  @singleton
  @Environment(Environment.prod)
  app_config.AppConfig get prodConfig => const app_config.AppConfig(
        environment: app_config.Environment.prod,
        apiBaseUrl: 'https://api.boklo.com',
        firebaseProjectId: 'boklo-prod',
        featureFlags: FeatureFlags(
          enableBiometrics: true,
        ),
      );

  @singleton
  FeatureFlags featureFlags(app_config.AppConfig config) => config.featureFlags;
}
