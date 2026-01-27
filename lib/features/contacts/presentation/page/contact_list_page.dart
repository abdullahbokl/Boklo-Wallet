import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boklo/core/services/snackbar_service.dart';

class ContactListPage extends StatelessWidget {
  const ContactListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<ContactCubit>();
        cubit.init();
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
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
                );
              },
            );
          },
        ),
      ),
    );
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
                decoration: const InputDecoration(labelText: 'Email'),
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
