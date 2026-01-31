class UsernameValidator {
  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  /// Validates a username.
  /// Returns null if valid, or an error message if invalid.
  static String? validate(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 20) {
      return 'Username must be at most 20 characters';
    }
    if (!_usernameRegex.hasMatch(username)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }
}
