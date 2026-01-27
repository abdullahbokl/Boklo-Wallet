import 'package:boklo/core/base/result.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';

abstract class ContactRepository {
  Stream<Result<List<ContactEntity>>> watchContacts();
  Future<Result<ContactEntity>> addContact(String email);
  // Future<Result<void>> removeContact(String uid); // Later
}
