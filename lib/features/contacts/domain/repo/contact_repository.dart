import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class ContactRepository {
  Stream<Either<Failure, List<ContactEntity>>> watchContacts();

  /// Add a contact by email or username
  Future<Either<Failure, ContactEntity>> addContact({
    String? email,
    String? username,
  });
  Future<Either<Failure, void>> removeContact(String uid);

  /// Marks (or unmarks) a contact as a favorite. Contact docs are
  /// owner-writable per Firestore rules, so this is a direct client write.
  Future<Either<Failure, void>> setFavorite({
    required String uid,
    required bool favorite,
  });
}
