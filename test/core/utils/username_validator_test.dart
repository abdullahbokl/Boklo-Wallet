import 'package:boklo/core/utils/username_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsernameValidator', () {
    test('valid usernames', () {
      expect(UsernameValidator.validate('abc'), null);
      expect(UsernameValidator.validate('user123'), null);
      expect(UsernameValidator.validate('my_name'), null);
    });

    test('invalid usernames', () {
      expect(UsernameValidator.validate(null), 'Username is required');
      expect(UsernameValidator.validate(''), 'Username is required');
      expect(UsernameValidator.validate('ab'),
          'Username must be at least 3 characters');
      expect(UsernameValidator.validate('a' * 21),
          'Username must be at most 20 characters');
      expect(UsernameValidator.validate('user-name'),
          'Only letters, numbers, and underscores allowed');
      expect(UsernameValidator.validate('user name'),
          'Only letters, numbers, and underscores allowed');
    });
  });
}
