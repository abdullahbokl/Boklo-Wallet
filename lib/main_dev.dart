import 'package:boklo/core/config/app_config.dart';
import 'package:boklo/core/config/feature_flags.dart';
import 'package:boklo/main_common.dart';

import 'package:boklo/firebase_options_dev.dart';

void main() async {
  const devConfig = AppConfig(
    environment: Environment.dev,
    apiBaseUrl: 'https://dev-api.boklo.com',
    firebaseProjectId: 'boklo-dev',
    featureFlags: FeatureFlags(
      enableBiometrics: true,
      enableBetaFeatures: true,
    ),
  );

  await bootstrap(devConfig, DefaultFirebaseOptions.currentPlatform);
}
