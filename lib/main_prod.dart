import 'package:boklo/core/config/app_config.dart';
import 'package:boklo/core/config/feature_flags.dart';
import 'package:boklo/main_common.dart';

import 'package:boklo/firebase_options_prod.dart';

void main() async {
  const prodConfig = AppConfig(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.boklo.com',
    firebaseProjectId: 'boklo-prod',
    featureFlags: FeatureFlags(
      enableBiometrics: true,
    ),
  );

  await bootstrap(prodConfig, DefaultFirebaseOptions.currentPlatform);
}
