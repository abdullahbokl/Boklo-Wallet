import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/wallet/domain/repositories/dispute_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: DisputeRepository)
class DisputeRepositoryImpl implements DisputeRepository {
  DisputeRepositoryImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<Either<Failure, void>> submitDispute({
    required String transactionId,
    required String walletId,
    required int amount,
    required String currency,
    required String reason,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return const Left(UnknownFailure('You must be signed in'));
      }
      final docRef = _firestore.collection('disputes').doc();
      await docRef.set({
        'id': docRef.id,
        'requesterId': uid,
        'transactionId': transactionId,
        'walletId': walletId,
        'amount': amount, // integer minor units
        'currency': currency,
        'reason': reason,
        'status': 'OPEN',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
