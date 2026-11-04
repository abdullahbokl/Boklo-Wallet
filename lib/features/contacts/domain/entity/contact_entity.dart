import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_entity.freezed.dart';

@freezed
abstract class ContactEntity with _$ContactEntity {
  const factory ContactEntity({
    required String uid,
    required String displayName,
    required String email,
    required DateTime createdAt,
    String? photoUrl,
    @Default(false) bool isFavorite,
  }) = _ContactEntity;
}
