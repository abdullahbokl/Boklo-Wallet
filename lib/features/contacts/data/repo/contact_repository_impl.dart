import 'dart:async';
import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/contacts/data/model/contact_model.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/domain/repo/contact_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ContactRepository)
class ContactRepositoryImpl implements ContactRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  ContactRepositoryImpl(this._firestore, this._auth, this._functions);

  @override
  Stream<Result<List<ContactEntity>>> watchContacts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(Failure(const UnknownError('User not logged in')));
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .transform(StreamTransformer<QuerySnapshot<Map<String, dynamic>>,
            Result<List<ContactEntity>>>.fromHandlers(
          handleData: (snapshot, sink) {
            try {
              final entities = snapshot.docs.map((doc) {
                return ContactModel.fromSnapshot(doc).toEntity();
              }).toList();
              sink.add(Success(entities));
            } catch (e) {
              sink.add(Failure(UnknownError(e.toString())));
            }
          },
          handleError: (error, stack, sink) {
            sink.add(Failure(UnknownError(error.toString())));
          },
        ));
    // Note: Using simpler map/handleError here.
    // If type inference fails like in PaymentRequestRepository,
    // I might need StreamTransformer or explicit cast.
    // Result<List<ContactEntity>> vs Success.
    // Dart might complain "Success is not Result".
    // Let's rely on covariance or use explicit cast if needed.
    // .map<Result<List<ContactEntity>>>
  }

  @override
  Future<Result<ContactEntity>> addContact(String email) async {
    try {
      final callable = _functions.httpsCallable('addContact');
      final result = await callable.call({'email': email});

      final data = result.data as Map<String, dynamic>;
      // data.contact is the contact object
      final contactMap = Map<String, dynamic>.from(data['contact'] as Map);

      // We might need to handle Timestamp if it comes back as specific format?
      // Cloud Functions usually return logic types or ISO strings for dates?
      // If it's pure JSON, it's string.
      // Our ContactModel handles String dates?
      // _timestampFromJson handles String.

      final model = ContactModel.fromJson(contactMap);
      return Success(model.toEntity());
    } on FirebaseFunctionsException catch (e) {
      return Failure(UnknownError(e.message ?? e.code));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeContact(String contactUid) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return Failure(const UnknownError('User not logged in'));
      }
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .doc(contactUid)
          .delete();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }
}
