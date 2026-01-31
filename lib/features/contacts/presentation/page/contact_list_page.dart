import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boklo/core/services/snackbar_service.dart';

class ContactListPage extends StatelessWidget {
  const ContactListPage({super.key, this.isPickMode = false});

  final bool isPickMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<ContactCubit>();
        cubit.init();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isPickMode ? 'Select Contact' : 'Contacts')),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showAddContactDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
        body: BlocBuilder<ContactCubit, BaseState<ContactState>>(
          builder: (context, state) {
            final contacts = state.data?.contacts ?? [];

            if (state.isLoading && contacts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (contacts.isEmpty) {
              return const Center(child: Text('No contacts yet'));
            }

            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  onTap: isPickMode
                      ? () => getIt<NavigationService>().pop(contact)
                      : null,
                  leading: CircleAvatar(
                    backgroundImage: contact.photoUrl != null
                        ? NetworkImage(contact.photoUrl!)
                        : null,
                    child: contact.photoUrl == null
                        ? Text(contact.displayName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(contact.displayName),
                  subtitle: Text(contact.email),
                  trailing: isPickMode
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (action) =>
                              _handleContactAction(context, action, contact),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'send',
                              child: Row(
                                children: [
                                  Icon(Icons.send, size: 20),
                                  SizedBox(width: 8),
                                  Text('Send Money'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'request',
                              child: Row(
                                children: [
                                  Icon(Icons.request_page, size: 20),
                                  SizedBox(width: 8),
                                  Text('Request Payment'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Remove',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleContactAction(
      BuildContext context, String action, ContactEntity contact) {
    if (action == 'send') {
      getIt<NavigationService>().push('/transfer', extra: contact);
    } else if (action == 'request') {
      getIt<NavigationService>()
          .push('/payment-requests/create', extra: contact);
    } else if (action == 'remove') {
      context.read<ContactCubit>().removeContact(contact.uid);
    }
  }

  void _showAddContactDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ContactCubit>(),
        child: BlocListener<ContactCubit, BaseState<ContactState>>(
          listener: (context, state) {
            state.whenOrNull(success: (data) {
              if (!data.isAdding) {
                Navigator.of(context).pop(); // Close dialog if success
              }
            }, error: (e) {
              getIt<SnackbarService>().showError(e.message);
            });
          },
          child: Builder(
            builder: (context) => AlertDialog(
              title: const Text('Add Contact'),
              content: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email or @username',
                  hintText: 'user@example.com or @username',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                BlocBuilder<ContactCubit, BaseState<ContactState>>(
                  builder: (context, state) {
                    final isAdding = state.data?.isAdding == true;
                    return TextButton(
                      onPressed: isAdding
                          ? null
                          : () {
                              context
                                  .read<ContactCubit>()
                                  .addContact(emailController.text);
                            },
                      child: isAdding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Add'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
