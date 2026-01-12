class FeatureFlags {
  const FeatureFlags({
    this.enableBiometrics = false,
    this.enableBetaFeatures = false,
    this.backendAuthoritativeTransfers = false,
  });

  final bool enableBiometrics;
  final bool enableBetaFeatures;
  final bool backendAuthoritativeTransfers;
}
