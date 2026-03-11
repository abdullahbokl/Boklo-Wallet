import 'package:boklo/core/config/app_feature_flags.dart';

enum Environment { dev, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.firebaseProjectId,
    required this.featureFlags,
  });

  final Environment environment;
  final String apiBaseUrl;
  final String firebaseProjectId;
  final AppFeatureFlags featureFlags;

  bool get isDev => environment == Environment.dev;
  bool get isProd => environment == Environment.prod;
}
