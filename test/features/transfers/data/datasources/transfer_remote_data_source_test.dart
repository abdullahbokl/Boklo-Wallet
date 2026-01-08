import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCollectionReference<T> extends Mock
    implements CollectionReference<T> {}

class MockDocumentReference<T> extends Mock implements DocumentReference<T> {}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  Transaction? _transactionToUse;
  final walletsCollection = MockCollectionReference<Map<String, dynamic>>();
  final transfersCollection = MockCollectionReference<Map<String, dynamic>>();

  void setTransactionToUse(Transaction transaction) {
    _transactionToUse = transaction;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    if (collectionPath == 'wallets') {
      return walletsCollection;
    }
    if (collectionPath == 'transfers') {
      return transfersCollection;
    }
    return super.noSuchMethod(Invocation.method(#collection, [collectionPath]))
        as CollectionReference<Map<String, dynamic>>;
  }

  @override
  Future<T> runTransaction<T>(TransactionHandler<T> updateFunction,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    if (_transactionToUse != null) {
      return await updateFunction(_transactionToUse!);
    }
    throw UnimplementedError('Transaction not set');
  }
}

class MockTransaction extends Mock implements Transaction {
  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data,
      [SetOptions? options]) {
    super.noSuchMethod(
        Invocation.method(#set, [documentReference, data, options]));
    return this;
  }

  @override
  Transaction update(
      DocumentReference documentReference, Map<String, Object?> data) {
    super.noSuchMethod(Invocation.method(#update, [documentReference, data]));
    return this;
  }
}

void main() {
  late TransferRemoteDataSourceImpl dataSource;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockWalletsCollection;
  late MockCollectionReference<Map<String, dynamic>> mockTransfersCollection;
  late MockDocumentReference<Map<String, dynamic>> mockFromWalletDoc;
  late MockDocumentReference<Map<String, dynamic>> mockToWalletDoc;
  late MockDocumentReference<Map<String, dynamic>> mockTransferDoc;

  setUp(() {
    registerFallbackValue(MockDocumentReference<Map<String, dynamic>>());
    registerFallbackValue(TransactionModel(
            id: '1',
            amount: 1,
            type: TransactionType.debit,
            timestamp: DateTime.now())
        .toJson());
    registerFallbackValue(<String, dynamic>{}); // Map<String, dynamic>
    registerFallbackValue(Duration.zero);
    registerFallbackValue((Transaction t) async {});
    registerFallbackValue(SetOptions(merge: true));

    mockFirestore = MockFirebaseFirestore();
    mockWalletsCollection = mockFirestore.walletsCollection;
    mockTransfersCollection = mockFirestore.transfersCollection;

    mockFromWalletDoc = MockDocumentReference();
    mockToWalletDoc = MockDocumentReference();
    mockTransferDoc = MockDocumentReference();

    // Default doc setup
    when(() => mockWalletsCollection.doc(any())).thenReturn(mockFromWalletDoc);
    when(() => mockTransfersCollection.doc(any())).thenReturn(mockTransferDoc);

    dataSource = TransferRemoteDataSourceImpl(mockFirestore);
  });

  group('createTransfer', () {
    final transferModel = TransferModel(
      id: 'transfer1',
      fromWalletId: 'walletA',
      toWalletId: 'walletB',
      amount: 100,
      currency: 'USD',
      status: TransferStatus.completed,
      createdAt: DateTime(2023),
    );

    test('should execute transaction successfully', () async {
      final mockTransaction = MockTransaction();
      mockFirestore.setTransactionToUse(mockTransaction);

      when(() => mockWalletsCollection.doc('walletA'))
          .thenReturn(mockFromWalletDoc);
      when(() => mockWalletsCollection.doc('walletB'))
          .thenReturn(mockToWalletDoc);

      final mockFromTxCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockToTxCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockFromTxDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockToTxDoc = MockDocumentReference<Map<String, dynamic>>();

      when(() => mockFromWalletDoc.collection('transactions'))
          .thenReturn(mockFromTxCollection);
      when(() => mockToWalletDoc.collection('transactions'))
          .thenReturn(mockToTxCollection);
      when(() => mockFromTxCollection.doc(any())).thenReturn(mockFromTxDoc);
      when(() => mockToTxCollection.doc(any())).thenReturn(mockToTxDoc);
      when(() => mockFromTxDoc.id).thenReturn('tx1');
      when(() => mockToTxDoc.id).thenReturn('tx2');

      final mockFromSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockToSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(() => mockTransaction.get(mockFromWalletDoc))
          .thenAnswer((_) async => mockFromSnapshot);
      when(() => mockTransaction.get(mockToWalletDoc))
          .thenAnswer((_) async => mockToSnapshot);

      when(() => mockFromSnapshot.exists).thenReturn(true);
      when(() => mockToSnapshot.exists).thenReturn(true);
      when(() => mockFromSnapshot.data()).thenReturn({'balance': 500.0});
      when(() => mockToSnapshot.data()).thenReturn({'balance': 200.0});

      await dataSource.createTransfer(transferModel);

      verify(() => mockTransaction.update(mockFromWalletDoc, any())).called(1);
      verify(() => mockTransaction.update(mockToWalletDoc, any())).called(1);
      verify(() => mockTransaction.set(mockTransferDoc, any())).called(1);
    });

    test('should throw Exception when balance is insufficient', () async {
      final mockTransaction = MockTransaction();
      mockFirestore.setTransactionToUse(mockTransaction);

      when(() => mockWalletsCollection.doc('walletA'))
          .thenReturn(mockFromWalletDoc);
      when(() => mockWalletsCollection.doc('walletB'))
          .thenReturn(mockToWalletDoc);

      // Necessary stubbing for refs creation (happens before transaction)
      final mockFromTxCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockToTxCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockTxDoc = MockDocumentReference<Map<String, dynamic>>();

      when(() => mockFromWalletDoc.collection('transactions'))
          .thenReturn(mockFromTxCollection);
      when(() => mockToWalletDoc.collection('transactions'))
          .thenReturn(mockToTxCollection);
      when(() => mockFromTxCollection.doc(any())).thenReturn(mockTxDoc);
      when(() => mockToTxCollection.doc(any())).thenReturn(mockTxDoc);

      final mockFromSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockToSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(() => mockTransaction.get(mockFromWalletDoc))
          .thenAnswer((_) async => mockFromSnapshot);
      when(() => mockTransaction.get(mockToWalletDoc))
          .thenAnswer((_) async => mockToSnapshot);

      when(() => mockFromSnapshot.exists).thenReturn(true);
      when(() => mockToSnapshot.exists).thenReturn(true);
      when(() => mockFromSnapshot.data())
          .thenReturn({'balance': 50.0}); // Insufficient
      when(() => mockToSnapshot.data()).thenReturn({'balance': 200.0});

      try {
        await dataSource.createTransfer(transferModel);
        fail('Should have thrown Exception');
      } catch (e) {
        expect(e.toString(), contains('Insufficient balance'));
      }

      verifyNever(() => mockTransaction.update(any(), any()));
    });
  });
}
