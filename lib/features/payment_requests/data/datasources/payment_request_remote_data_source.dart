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
    print('[DEBUG] watchIncomingRequests: uid=$uid');
    if (uid == null) {
      print('[DEBUG] watchIncomingRequests: No user, returning empty');
      return Stream.value([]);
    }

    return _firestore
        .collection('payment_requests')
        .where('payerId', isEqualTo: uid)
        // Temporarily removing orderBy to test if index is the issue
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Debug log
      print(
          '[DEBUG] watchIncomingRequests: ${snapshot.docs.length} docs for payerId=$uid');
      for (var doc in snapshot.docs) {
        print('[DEBUG] Incoming doc: ${doc.id} - ${doc.data()}');
      }
      return snapshot.docs
          .map((doc) => PaymentRequestModel.fromSnapshot(doc))
          .toList();
    }).handleError((Object error) {
      print('[ERROR] watchIncomingRequests error: $error');
    });
  }

  @override
  Stream<List<PaymentRequestModel>> watchOutgoingRequests() {
    final uid = _auth.currentUser?.uid;
    print('[DEBUG] watchOutgoingRequests: uid=$uid');
    if (uid == null) {
      print('[DEBUG] watchOutgoingRequests: No user, returning empty');
      return Stream.value([]);
    }

    return _firestore
        .collection('payment_requests')
        .where('requesterId', isEqualTo: uid)
        // Temporarily removing orderBy to test if index is the issue
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Debug log
      print(
          '[DEBUG] watchOutgoingRequests: ${snapshot.docs.length} docs for requesterId=$uid');
      for (var doc in snapshot.docs) {
        print('[DEBUG] Outgoing doc: ${doc.id} - ${doc.data()}');
      }
      return snapshot.docs
          .map((doc) => PaymentRequestModel.fromSnapshot(doc))
          .toList();
    }).handleError((Object error) {
      print('[ERROR] watchOutgoingRequests error: $error');
    });
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
