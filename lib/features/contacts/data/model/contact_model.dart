import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_model.freezed.dart';
part 'contact_model.g.dart';

@freezed
class ContactModel with _$ContactModel {
  const ContactModel._();

  const factory ContactModel({
    required String uid,
    required String displayName,
    @JsonKey(name: 'photoUrl') String? photoUrl,
    required String email,
    @JsonKey(
        name: 'createdAt',
        fromJson: _timestampFromJson,
        toJson: _timestampToJson)
    required DateTime createdAt,
  }) = _ContactModel;

  factory ContactModel.fromJson(Map<String, dynamic> json) =>
      _$ContactModelFromJson(json);

  factory ContactModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // uid might be doc id or field? In Cloud Function we set doc(contactUid).set(contactData).
    // And contactData contained 'uid'.
    // So both are valid.
    return ContactModel.fromJson(data);
  }

  ContactEntity toEntity() {
    return ContactEntity(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      email: email,
      createdAt: createdAt,
    );
  }
}

DateTime _timestampFromJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  }
  return DateTime.now(); // Fallback
}

dynamic _timestampToJson(DateTime date) => Timestamp.fromDate(date);
