import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/contacts/data/repo/contact_repository_impl.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockContactRepository extends Mock implements ContactRepositoryImpl {}

ContactEntity _contact({
  required String uid,
  bool isFavorite = false,
  DateTime? createdAt,
}) {
  return ContactEntity(
    uid: uid,
    displayName: 'Contact $uid',
    email: '$uid@example.com',
    createdAt: createdAt ?? _defaultDate,
    isFavorite: isFavorite,
  );
}

final _defaultDate = DateTime(2024);

void main() {
  late ContactCubit cubit;
  late MockContactRepository repository;

  setUp(() {
    repository = MockContactRepository();
    cubit = ContactCubit(repository);
    registerFallbackValue(_contact(uid: 'fallback'));
  });

  tearDown(() async {
    await cubit.close();
  });

  group('ContactCubit favorites', () {
    test('toggleFavorite flips the flag and sorts favorites first', () async {
      final plain = _contact(uid: 'a', createdAt: DateTime(2024, 1, 2));
      final starred = _contact(uid: 'b', createdAt: DateTime(2024, 1, 3));
      final contacts = [plain, starred];

      when(() => repository.watchContacts()).thenAnswer(
        (_) => Stream.value(Right<Failure, List<ContactEntity>>(contacts)),
      );
      when(() => repository.setFavorite(uid: 'a', favorite: true)).thenAnswer(
        (_) async => const Right<Failure, void>(null),
      );

      cubit.init();
      await Future<void>.delayed(Duration.zero);

      // Toggle 'a' to favorite.
      await cubit.toggleFavorite(plain);

      final state = cubit.state.data!;
      expect(state.contacts.first.uid, 'a'); // favorite sorts first
      expect(state.contacts.first.isFavorite, isTrue);
      verify(() => repository.setFavorite(uid: 'a', favorite: true)).called(1);
    });

    test('toggleFavorite reverts optimistic update on failure', () async {
      final plain = _contact(uid: 'a');

      when(() => repository.watchContacts()).thenAnswer(
        (_) => Stream.value(Right<Failure, List<ContactEntity>>([plain])),
      );
      when(() => repository.setFavorite(uid: 'a', favorite: true)).thenAnswer(
        (_) async => const Left<Failure, void>(UnknownFailure('offline')),
      );

      cubit.init();
      await Future<void>.delayed(Duration.zero);

      await cubit.toggleFavorite(plain);

      // Optimistic favorite was reverted by the failure path.
      final state = cubit.state.data!;
      expect(state.contacts.first.isFavorite, isFalse);
    });

    test('stream results sort favorites before plain contacts', () async {
      final c1 = _contact(uid: 'a');
      final c2 = _contact(uid: 'b', isFavorite: true);
      final c3 = _contact(uid: 'c');

      when(() => repository.watchContacts()).thenAnswer(
        (_) => Stream.value(Right<Failure, List<ContactEntity>>([c1, c2, c3])),
      );

      cubit.init();
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.data!.contacts.map((c) => c.uid).toList(),
        ['b', 'a', 'c'],
      );
    });
  });
}
