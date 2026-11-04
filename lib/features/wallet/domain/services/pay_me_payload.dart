/// Encoding/decoding of Boklo pay-me QR payloads.
///
/// The QR carries a `boklo://pay?u=<identifier>` deep-link-style URI where
/// `<identifier>` is the receiver's username (or wallet alias). Scanning
/// with any QR reader shows the URI; Boklo's in-app scanner parses it and
/// prefills the transfer recipient.
library;

class PayMePayload {
  const PayMePayload._();

  static const scheme = 'boklo';
  static const host = 'pay';

  /// Encodes an identifier (username or alias) into the QR payload URI.
  static String encode(String identifier) {
    final normalized = identifier.trim();
    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: {'u': normalized},
    ).toString();
  }

  /// Decodes a scanned QR string into the recipient identifier.
  ///
  /// Returns null for anything that is not a Boklo pay-me payload. Plain
  /// identifier text (a bare username without the scheme) is also accepted
  /// so manually-typed codes still work.
  static String? decode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    final recipient = uri?.queryParameters['u'];
    if (uri != null &&
        uri.scheme == scheme &&
        uri.host == host &&
        recipient != null &&
        recipient.isNotEmpty) {
      return recipient;
    }

    // Bare identifier fallback (no scheme, no whitespace).
    if (uri == null || (uri.scheme.isEmpty && !trimmed.contains(' '))) {
      return trimmed;
    }
    return null;
  }
}
