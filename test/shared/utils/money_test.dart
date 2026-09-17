import 'package:boklo/shared/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'en_US';
  });

  group('tryParseMoney', () {
    test('parses major-unit input into minor units', () {
      expect(tryParseMoney('10.5'), 1050);
      expect(tryParseMoney('100'), 10000);
      expect(tryParseMoney(' 1,250.50 '), 125050);
    });

    test('rejects invalid or non-positive input', () {
      expect(tryParseMoney('abc'), isNull);
      expect(tryParseMoney(''), isNull);
      expect(tryParseMoney('0'), isNull);
      expect(tryParseMoney('-5'), isNull);
    });

    test('rounds float drift instead of truncating', () {
      expect(tryParseMoney('0.1'), 10);
      expect(tryParseMoney('19.99'), 1999);
    });
  });

  group('moneyLabel', () {
    test('formats minor units with currency code', () {
      expect(1050.moneyLabel('EGP'), 'EGP 10.50');
      expect(5.moneyLabel('EGP'), 'EGP 0.05');
      expect(0.moneyLabel('SAR'), 'SAR 0.00');
      expect(123456789.moneyLabel('USD'), 'USD 1,234,567.89');
    });
  });
}
