import 'package:boklo/features/wallet/domain/services/pay_me_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayMePayload', () {
    test('encode produces a boklo://pay URI with the identifier', () {
      expect(
        PayMePayload.encode('john_doe'),
        'boklo://pay?u=john_doe',
      );
    });

    test('encode trims the identifier', () {
      expect(PayMePayload.encode('  ali  '), 'boklo://pay?u=ali');
    });

    test('decode round-trips an encoded payload', () {
      final payload = PayMePayload.encode('john_doe');
      expect(PayMePayload.decode(payload), 'john_doe');
    });

    test('decode accepts a bare username fallback', () {
      expect(PayMePayload.decode('john_doe'), 'john_doe');
    });

    test('decode accepts a bare @handle', () {
      expect(PayMePayload.decode('@john_doe'), '@john_doe');
    });

    test('decode rejects foreign URIs', () {
      expect(PayMePayload.decode('https://example.com/pay?u=x'), isNull);
      expect(PayMePayload.decode('boklo://other?u=x'), isNull);
    });

    test('decode rejects pay payloads without an identifier', () {
      expect(PayMePayload.decode('boklo://pay'), isNull);
      expect(PayMePayload.decode('boklo://pay?u='), isNull);
    });

    test('decode rejects empty and whitespace input', () {
      expect(PayMePayload.decode(''), isNull);
      expect(PayMePayload.decode('   '), isNull);
    });
  });
}
