import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:boklo/features/contacts/presentation/widgets/add_contact_sheet.dart';
import 'package:boklo/features/contacts/presentation/widgets/contact_item.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactListPage extends StatelessWidget {
  const ContactListPage({
    super.key,
    this.isPickMode = false,
  });

  final bool isPickMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContactCubit>()..init(),
      child: AppPageScaffold(
        title: isPickMode ? 'Select contact' : 'Contacts',
        floatingActionButton: FloatingActionButton(
          onPressed: () => AddContactSheet.show(
            context,
            context.read<ContactCubit>(),
          ),
          child: const Icon(Icons.person_add_alt_1_rounded),
        ),
        child: _ContactListBody(isPickMode: isPickMode),
      ),
    );
  }
}

class _ContactListBody extends StatelessWidget {
  const _ContactListBody({required this.isPickMode});

  final bool isPickMode;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactCubit, BaseState<ContactState>>(
      listener: (context, state) {
        state.whenOrNull(
          error: (e) => getIt<SnackbarService>().showError(e.message),
        );
      },
      builder: (context, state) {
        final contacts = state.data?.contacts ?? [];

        if (state.isLoading && contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (contacts.isEmpty) {
          return AppEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No contacts yet',
            subtitle: 'Add trusted contacts to send or request money faster.',
            actionLabel: 'Add contact',
            onAction: () => AddContactSheet.show(
              context,
              context.read<ContactCubit>(),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: AppDimens.md, bottom: AppDimens.xxl),
          children: [
            AppSectionHeader(
              title: 'Your network',
              subtitle: isPickMode
                  ? 'Choose who should receive this action.'
                  : 'People you can pay or request money from.',
            ),
            const SizedBox(height: AppDimens.md),
            ...contacts.map(
              (contact) => ContactItem(
                contact: contact,
                isPickMode: isPickMode,
                onTap: isPickMode
                    ? () => getIt<NavigationService>().pop(contact)
                    : null,
                onSendMoney: () => getIt<NavigationService>()
                    .push('/transfer', extra: contact),
                onRequestMoney: () => getIt<NavigationService>()
                    .push('/payment-requests/create', extra: contact),
                onRemove: () => context.read<ContactCubit>().removeContact(
                      contact.uid,
                    ),
              ),
            ),
          ],
        );
      },
    );
  }
}
