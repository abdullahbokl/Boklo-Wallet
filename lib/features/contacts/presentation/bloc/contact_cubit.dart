import 'dart:async';
import 'package:boklo/core/base/base_cubit.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/domain/repo/contact_repository.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class ContactCubit extends BaseCubit<ContactState> {
  final ContactRepository _repository;
  StreamSubscription? _sub;

  ContactCubit(this._repository) : super(const BaseState.initial());

  void init() {
    emitLoading();
    _sub?.cancel();
    _sub = _repository.watchContacts().listen((result) {
      result.fold(
        (error) => emitError(error),
        (data) {
          final current = state.data ?? const ContactState();
          emitSuccess(current.copyWith(contacts: data));
        },
      );
    });
  }

  /// Add a contact by email or username
  /// Detects format: if contains @ and not starting with @ → email
  /// Otherwise → username
  Future<void> addContact(String identifier) async {
    final current = state.data ?? const ContactState();
    emitSuccess(current.copyWith(isAdding: true));

    final trimmed = identifier.trim();
    final bool isEmail = trimmed.contains('@') && !trimmed.startsWith('@');

    final result = isEmail
        ? await _repository.addContact(email: trimmed)
        : await _repository.addContact(username: trimmed.replaceFirst('@', ''));

    result.fold(
      (error) {
        emitError(error);
        emitSuccess(current.copyWith(isAdding: false));
      },
      (contact) {
        // Optimistic Update: Add to list immediately
        final updatedList = List<ContactEntity>.from(current.contacts)
          ..insert(0, contact); // Add to top

        emitSuccess(current.copyWith(
          isAdding: false,
          contacts: updatedList,
        ));
      },
    );
  }

  Future<void> removeContact(String contactUid) async {
    final current = state.data ?? const ContactState();

    // Optimistic update
    final updatedList = List<ContactEntity>.from(current.contacts)
      ..removeWhere((c) => c.uid == contactUid);

    emitSuccess(current.copyWith(contacts: updatedList));

    final result = await _repository.removeContact(contactUid);

    result.fold(
      (error) {
        // Revert on failure
        emitError(error);
        emitSuccess(current);
      },
      (_) {
        // Success - stream will confirm
      },
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
