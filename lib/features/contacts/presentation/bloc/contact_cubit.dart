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

  Future<void> addContact(String email) async {
    final current = state.data ?? const ContactState();
    emitSuccess(current.copyWith(isAdding: true));

    final result = await _repository.addContact(email);

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

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
