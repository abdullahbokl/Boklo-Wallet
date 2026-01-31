import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';

abstract class ContactRepository {
  Stream<Result<List<ContactEntity>>> watchContacts();

  /// Add a contact by email or username
  Future<Result<ContactEntity>> addContact({String? email, String? username});
  Future<Result<void>> removeContact(String uid);
}
