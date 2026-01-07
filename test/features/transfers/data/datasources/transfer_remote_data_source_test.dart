import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/wallet/data/models/transaction_model.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  Transaction? _transactionToUse;

  void setTransactionToUse(Transaction transaction) {
    _transactionToUse = transaction;
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

class MockCollectionReference<T> extends Mock
    implements CollectionReference<T> {}

class MockDocumentReference<T> extends Mock implements DocumentReference<T> {}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {}

class MockTransaction extends Mock implements Transaction {}

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

    mockFirestore = MockFirebaseFirestore();
    mockWalletsCollection = MockCollectionReference();
    mockTransfersCollection = MockCollectionReference();
    mockFromWalletDoc = MockDocumentReference();
    mockToWalletDoc = MockDocumentReference();
    mockTransferDoc = MockDocumentReference();

    when(() => mockFirestore.collection('wallets'))
        .thenReturn(mockWalletsCollection);
    when(() => mockFirestore.collection('transfers'))
        .thenReturn(mockTransfersCollection);

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
      // Arrange
      final mockTransaction = MockTransaction();

      // Mock runTransaction to execute the closure
      // Configure manually
      mockFirestore.setTransactionToUse(mockTransaction);

      // Setup specific wallet docs
      when(() => mockWalletsCollection.doc('walletA'))
          .thenReturn(mockFromWalletDoc);
      when(() => mockWalletsCollection.doc('walletB'))
          .thenReturn(mockToWalletDoc);

      // Setup subcollections for transactions
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

      // Mock Snapshots
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

      when(() => mockTransaction.update(any(), any()))
          .thenReturn(mockTransaction);
      when(() => mockTransaction.set(any(), any())).thenReturn(mockTransaction);

      // Act
      await dataSource.createTransfer(transferModel);

      // Assert
      // Assert
      // Verify updates
      verify(() => mockTransaction.update(mockFromWalletDoc, any())).called(1);
      verify(() => mockTransaction.update(mockToWalletDoc, any())).called(1);

      // Verify transfer doc set
      verify(() => mockTransaction.set(mockTransferDoc, any())).called(1);
    });

    test('should throw Exception when balance is insufficient', () async {
      // Arrange
      final mockTransaction = MockTransaction();

      // Configure manually
      mockFirestore.setTransactionToUse(mockTransaction);

      when(() => mockWalletsCollection.doc('walletA'))
          .thenReturn(mockFromWalletDoc);
      when(() => mockWalletsCollection.doc('walletB'))
          .thenReturn(mockToWalletDoc);

      // Mock Snapshots
      final mockFromSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      // Using generic mock for second wallet get as we fail before processing it fully or right after
      // Actually code gets both first.
      final mockToSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(() => mockTransaction.get(mockFromWalletDoc))
          .thenAnswer((_) async => mockFromSnapshot);
      when(() => mockTransaction.get(mockToWalletDoc))
          .thenAnswer((_) async => mockToSnapshot);

      when(() => mockFromSnapshot.exists).thenReturn(true);
      when(() => mockToSnapshot.exists).thenReturn(true);
      when(() => mockFromSnapshot.data())
          .thenReturn({'balance': 50.0}); // Less than 100
      when(() => mockToSnapshot.data()).thenReturn({'balance': 200.0});

      // Act & Assert
      await expectLater(
        () => dataSource.createTransfer(transferModel),
        throwsA(
            predicate((e) => e.toString().contains('Insufficient balance'))),
      );

      verifyNever(() => mockTransaction.update(any(), any()));
    });
  });
}
