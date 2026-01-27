import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_state.freezed.dart';

@freezed
class ContactState with _$ContactState {
  const factory ContactState({
    @Default([]) List<ContactEntity> contacts,
    @Default(false) bool isAdding,
  }) = _ContactState;
}
