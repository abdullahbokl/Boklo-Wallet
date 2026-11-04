import 'package:boklo/l10n/generated/app_localizations.dart';

/// Maps machine-readable backend transfer error codes (stamped on failed
/// transfer docs as `errorCode`) to localized user-facing messages, falling
/// back to the raw backend text for unknown codes.
String localizedTransferError(
  AppLocalizations l10n, {
  String? errorCode,
  String? fallback,
}) {
  return switch (errorCode) {
    'INSUFFICIENT_BALANCE' => l10n.errInsufficientBalance,
    'WALLET_NOT_FOUND' => l10n.errWalletNotFound,
    'CURRENCY_MISMATCH' => l10n.errCurrencyMismatch,
    'WALLET_NOT_MIGRATED' => l10n.errWalletNotMigrated,
    'TRANSFER_ALREADY_PROCESSED' => l10n.errAlreadyProcessed,
    'TRANSFER_FAILED' => l10n.errTransferFailed,
    // Legacy failures (pre-errorCode) are matched on their stored English
    // failure text so historical transfers localize too.
    _ =>
      _matchLegacyMessage(l10n, fallback) ?? fallback ?? l10n.errTransferFailed,
  };
}

String? _matchLegacyMessage(AppLocalizations l10n, String? message) {
  if (message == null) return null;
  if (message.startsWith('wallet-not-migrated')) {
    return l10n.errWalletNotMigrated;
  }
  if (message.startsWith('currency-mismatch')) {
    return l10n.errCurrencyMismatch;
  }
  if (message == 'Insufficient balance') return l10n.errInsufficientBalance;
  if (message == 'One or both wallets do not exist') {
    return l10n.errWalletNotFound;
  }
  return null;
}
