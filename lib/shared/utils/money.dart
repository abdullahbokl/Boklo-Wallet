import 'package:intl/intl.dart';

/// Monetary values throughout the app are INTEGER MINOR UNITS
/// (e.g. piastres for EGP: `1050` = `EGP 10.50`). Firestore stores the
/// same representation and stamps documents with `minorUnits: true`.
extension MoneyFormatting on int {
  /// Formats a minor-unit amount with its currency code,
  /// e.g. `1050` + `EGP` → `EGP 10.50`.
  ///
  /// All user-facing money display MUST go through this (or an equivalent
  /// intl-based formatter); never interpolate raw amounts.
  String moneyLabel(String currency) {
    return NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 2,
    ).format(this / 100);
  }
}

/// Parses user-typed major-unit amounts (`"1250.50"`) into integer minor
/// units (`125050`). Returns null for invalid or non-positive input.
int? tryParseMoney(String input) {
  final normalized = input.trim().replaceAll(',', '');
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) {
    return null;
  }
  return (value * 100).round();
}
