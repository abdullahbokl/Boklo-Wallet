import 'package:intl/intl.dart';

extension MoneyFormatting on double {
  /// Formats a monetary amount together with its currency code,
  /// e.g. `1250.5` + `EGP` → `EGP 1,250.50`.
  ///
  /// All user-facing money display MUST go through this (or an equivalent
  /// intl-based formatter); never use `toStringAsFixed` or raw
  /// interpolation for monetary values.
  String moneyLabel(String currency) {
    return NumberFormat.currency(
      symbol: '$currency ',
      decimalDigits: 2,
    ).format(this);
  }
}
