import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed

/// Domain entity representing a user.
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    String? username,
  }) = _User;
}
