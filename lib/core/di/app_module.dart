import 'package:boklo/core/config/app_config.dart' as app_config;
import 'package:boklo/core/config/app_feature_flags.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage => const FlutterSecureStorage();

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firebaseFirestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseFunctions get firebaseFunctions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');

  @lazySingleton
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @singleton
  @Environment(Environment.dev)
  app_config.AppConfig get devConfig => const app_config.AppConfig(
    environment: app_config.Environment.dev,
    apiBaseUrl: 'https://dev-api.boklo.com',
    firebaseProjectId: 'boklo-dev',
    featureFlags: AppFeatureFlags(
      enableBiometrics: true,
      enableBetaFeatures: true,
      backendAuthoritativeTransfers: true,
    ),
  );

  @singleton
  @Environment(Environment.prod)
  app_config.AppConfig get prodConfig => const app_config.AppConfig(
    environment: app_config.Environment.prod,
    apiBaseUrl: 'https://api.boklo.com',
    firebaseProjectId: 'boklo-prod',
    featureFlags: AppFeatureFlags(
      enableBiometrics: true,
      backendAuthoritativeTransfers: true,
    ),
  );

  @singleton
  AppFeatureFlags featureFlags(app_config.AppConfig config) =>
      config.featureFlags;
}
