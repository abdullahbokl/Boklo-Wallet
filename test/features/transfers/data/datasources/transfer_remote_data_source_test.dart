import 'package:boklo/features/transfers/data/datasources/transfer_remote_data_source.dart';
import 'package:boklo/features/transfers/data/models/transfer_model.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCollectionReference<T> extends Mock
    implements CollectionReference<T> {}

class MockDocumentReference<T> extends Mock implements DocumentReference<T> {}

class MockDocumentSnapshot<T> extends Mock implements DocumentSnapshot<T> {}

class MockTransaction extends Mock implements Transaction {
  DocumentReference? lastSetRef;
  Map<String, dynamic>? lastSetData;

  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data,
      [SetOptions? options]) {
    lastSetRef = documentReference;
    lastSetData = data as Map<String, dynamic>;
    return this;
  }
}

class FakeDocumentSnapshot<T> extends Fake implements DocumentSnapshot<T> {
  final bool _exists;
  final T? _data;

  FakeDocumentSnapshot(this._exists, [this._data]);

  @override
  bool get exists => _exists;

  @override
  T? data() => _data;
}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {
  Transaction? transactionToUse;

  @override
  Future<T> runTransaction<T>(TransactionHandler<T> updateFunction,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    return updateFunction(transactionToUse ?? MockTransaction());
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return super.noSuchMethod(Invocation.method(#collection, [collectionPath]))
        as CollectionReference<Map<String, dynamic>>;
  }
}

void main() {
  late TransferRemoteDataSourceImpl dataSource;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockTransfersCollection;
  late MockDocumentReference<Map<String, dynamic>> mockTransferDoc;
  late MockTransaction mockTransaction;

  setUpAll(() {
    registerFallbackValue((Transaction t) async {});
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MockDocumentReference<Map<String, dynamic>>());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockTransfersCollection = MockCollectionReference();
    mockTransferDoc = MockDocumentReference();
    mockTransaction = MockTransaction();

    dataSource = TransferRemoteDataSourceImpl(mockFirestore);

    when(() => mockFirestore.collection('transfers'))
        .thenReturn(mockTransfersCollection);
    when(() => mockTransfersCollection.doc(any())).thenReturn(mockTransferDoc);

    // Stub set to return the transaction itself (fluent API)
    // Use explicit generic to match the call
    // when(() => mockTransaction.set<Map<String, dynamic>>(any(), any()))
    //     .thenReturn(mockTransaction);

    // Inject the mock transaction directly into our fake
    mockFirestore.transactionToUse = mockTransaction;
  });

  group('createTransfer', () {
    final transferModel = TransferModel(
      id: 'transfer1',
      fromWalletId: 'walletA',
      toWalletId: 'walletB',
      amount: 100,
      currency: 'USD',
      status: TransferStatus.pending,
      createdAt: DateTime(2023),
    );

    test(
        'should create transfer document in transaction when it does not exist',
        () async {
      // Arrange
      // createTransfer checks if doc exists. We return a fake snapshot that says usage exists=false
      final fakeSnapshot = FakeDocumentSnapshot<Map<String, dynamic>>(false);

      when(() => mockTransaction.get(mockTransferDoc))
          .thenAnswer((_) async => fakeSnapshot);

      // Act
      await dataSource.createTransfer(transferModel);

      // Assert
      verify(() => mockFirestore.collection('transfers')).called(1);
      verify(() => mockTransfersCollection.doc(transferModel.id)).called(1);
      // verify(() => mockFirestore.runTransaction(any())).called(1); // Manual fake executes it, cannot verify with any()
      verify(() => mockTransaction.get(mockTransferDoc)).called(1);

      // Manual verification of set
      expect(mockTransaction.lastSetData, equals(transferModel.toJson()));
    });

    test('should throw Exception when transfer document already exists',
        () async {
      // Arrange
      final fakeSnapshot = FakeDocumentSnapshot<Map<String, dynamic>>(true);

      when(() => mockTransaction.get(mockTransferDoc))
          .thenAnswer((_) async => fakeSnapshot);

      // Act
      final call = dataSource.createTransfer;

      // Assert
      expect(
        () => call(transferModel),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('already exists'),
        )),
      );

      verify(() => mockTransaction.get(mockTransferDoc)).called(1);
      expect(mockTransaction.lastSetData, isNull);
    });
  });
}
