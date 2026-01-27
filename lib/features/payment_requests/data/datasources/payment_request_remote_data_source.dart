import 'package:boklo/features/payment_requests/data/model/payment_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

abstract class PaymentRequestRemoteDataSource {
  Future<String> createRequest(Map<String, dynamic> data);
  Stream<List<PaymentRequestModel>> watchIncomingRequests();
  Stream<List<PaymentRequestModel>> watchOutgoingRequests();
  Future<void> acceptRequest(String requestId);
  Future<void> declineRequest(String requestId);
}

@LazySingleton(as: PaymentRequestRemoteDataSource)
class PaymentRequestRemoteDataSourceImpl
    implements PaymentRequestRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  PaymentRequestRemoteDataSourceImpl(
      this._firestore, this._functions, this._auth);

  @override
  Future<String> createRequest(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final ref = _firestore.collection('payment_requests').doc();
    await ref.set({
      ...data,
      'requesterId': uid,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Stream<List<PaymentRequestModel>> watchIncomingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('payment_requests')
        .where('payerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRequestModel.fromSnapshot(
                doc)) // Ensure this constructor exists or map data
            .toList());
  }

  @override
  Stream<List<PaymentRequestModel>> watchOutgoingRequests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('payment_requests')
        .where('requesterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentRequestModel.fromSnapshot(doc))
            .toList());
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    final callable = _functions.httpsCallable('acceptPaymentRequest');
    await callable.call({'requestId': requestId});
  }

  @override
  Future<void> declineRequest(String requestId) async {
    final callable = _functions.httpsCallable('declinePaymentRequest');
    await callable.call({'requestId': requestId});
  }
}
