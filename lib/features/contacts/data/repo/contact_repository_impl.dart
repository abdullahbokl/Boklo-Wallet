import 'dart:async';

import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/contacts/data/model/contact_model.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/domain/repo/contact_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ContactRepository)
class ContactRepositoryImpl implements ContactRepository {

  ContactRepositoryImpl(this._firestore, this._auth, this._functions);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  @override
  Stream<Either<Failure, List<ContactEntity>>> watchContacts() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const Left(UnknownFailure('User not logged in')));
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .transform(StreamTransformer<QuerySnapshot<Map<String, dynamic>>,
            Either<Failure, List<ContactEntity>>>.fromHandlers(
          handleData: (snapshot, sink) {
            try {
              final entities = snapshot.docs.map((doc) {
                return ContactModel.fromSnapshot(doc).toEntity();
              }).toList();
              sink.add(Right(entities));
            } catch (e) {
              sink.add(Left(UnknownFailure(e.toString())));
            }
          },
          handleError: (error, stack, sink) {
            sink.add(Left(UnknownFailure(error.toString())));
          },
        ),);
  }

  @override
  Future<Either<Failure, ContactEntity>> addContact({
    String? email,
    String? username,
  }) async {
    try {
      if (email == null && username == null) {
        return const Left(UnknownFailure('Must provide email or username'));
      }

      final callable = _functions.httpsCallable('addContact');
      final result = await callable.call<Map<String, dynamic>>({
        if (email != null) 'email': email,
        if (username != null) 'username': username,
      });

      final data = result.data;
      final contactMap = Map<String, dynamic>.from(data['contact'] as Map);

      final model = ContactModel.fromJson(contactMap);
      return Right(model.toEntity());
    } on FirebaseFunctionsException catch (e) {
      return Left(UnknownFailure(e.message ?? e.code));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeContact(String contactUid) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return const Left(UnknownFailure('User not logged in'));
      }
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .doc(contactUid)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
