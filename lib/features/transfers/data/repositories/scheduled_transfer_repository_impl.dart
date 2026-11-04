import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/transfers/domain/entities/scheduled_transfer_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Recurring transfers: Firestore list (owner-readable per rules) +
/// validated Cloud Function callables for create/cancel.
abstract class ScheduledTransferRepository {
  Stream<Either<Failure, List<ScheduledTransferEntity>>> watchSchedules();

  Future<Either<Failure, String>> createSchedule({
    required String toWalletId,
    required int amountMinor,
    required String currency,
    required ScheduleFrequency frequency,
    String? note,
  });

  Future<Either<Failure, void>> cancelSchedule(String id);
}

@LazySingleton(as: ScheduledTransferRepository)
class ScheduledTransferRepositoryImpl implements ScheduledTransferRepository {
  ScheduledTransferRepositoryImpl(this._firestore, this._auth)
    : _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  ScheduledTransferEntity _fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final createdAt = data['nextRunAt'];
    return ScheduledTransferEntity(
      id: doc.id,
      toWalletId: data['toWalletId'] as String? ?? '',
      amount: (data['amount'] as num).toInt(),
      currency: data['currency'] as String? ?? '',
      frequency: switch (data['frequency']) {
        'weekly' => ScheduleFrequency.weekly,
        'monthly' => ScheduleFrequency.monthly,
        _ => ScheduleFrequency.daily,
      },
      status: switch (data['status']) {
        'PAUSED' => ScheduleStatus.paused,
        'CANCELLED' => ScheduleStatus.cancelled,
        'COMPLETED' => ScheduleStatus.completed,
        _ => ScheduleStatus.active,
      },
      nextRunAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      note: data['note'] as String?,
      runCount: (data['runCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Stream<Either<Failure, List<ScheduledTransferEntity>>> watchSchedules() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(const Left(UnknownFailure('User not logged in')));
    }
    return _firestore
        .collection('scheduled_transfers')
        .where('fromWalletId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map<Either<Failure, List<ScheduledTransferEntity>>>(
          (snapshot) => Right(
            snapshot.docs.map(_fromDoc).where((s) {
              return s.status == ScheduleStatus.active ||
                  s.status == ScheduleStatus.paused;
            }).toList(),
          ),
        )
        .handleError(
          (Object e) => Left<Failure, List<ScheduledTransferEntity>>(
            UnknownFailure(e.toString()),
          ),
        );
  }

  @override
  Future<Either<Failure, String>> createSchedule({
    required String toWalletId,
    required int amountMinor,
    required String currency,
    required ScheduleFrequency frequency,
    String? note,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createScheduledTransfer')
          .call<Map<String, dynamic>>({
            'toWalletId': toWalletId,
            'amount': amountMinor,
            'currency': currency,
            'frequency': frequency.name,
            'note': ?note,
          });
      return Right(result.data['id'] as String);
    } on FirebaseFunctionsException catch (e) {
      return Left(UnknownFailure(e.message ?? e.code));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelSchedule(String id) async {
    try {
      await _functions
          .httpsCallable('cancelScheduledTransfer')
          .call<Map<String, dynamic>>({'id': id});
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(UnknownFailure(e.message ?? e.code));
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
