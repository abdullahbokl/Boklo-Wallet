import 'package:injectable/injectable.dart';

@injectable
class FeatureFlags {
  const FeatureFlags({
    this.enableBiometrics = false,
    this.enableBetaFeatures = false,
  });

  final bool enableBiometrics;
  final bool enableBetaFeatures;
}
