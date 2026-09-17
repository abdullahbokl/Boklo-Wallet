class AppFeatureFlags {
  const AppFeatureFlags({
    this.enableBiometrics = false,
    this.enableBetaFeatures = false,
    this.enableLedgerDebug = false,
  });

  final bool enableBiometrics;
  final bool enableBetaFeatures;

  /// Exposes the developer-only ledger debug screen. Never enable in
  /// production builds.
  final bool enableLedgerDebug;
}
