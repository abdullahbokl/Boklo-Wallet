import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:boklo/features/contacts/presentation/widgets/add_contact_sheet.dart';
import 'package:boklo/features/contacts/presentation/widgets/contact_item.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
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
        title: isPickMode ? context.l10n.selectContact : context.l10n.contacts,
        floatingActionButton: FloatingActionButton(
          tooltip: context.l10n.addContact,
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

class _ContactListBody extends StatefulWidget {
  const _ContactListBody({required this.isPickMode});

  final bool isPickMode;

  @override
  State<_ContactListBody> createState() => _ContactListBodyState();
}

class _ContactListBodyState extends State<_ContactListBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactCubit, BaseState<ContactState>>(
      listener: (context, state) {
        state.whenOrNull(
          error: (e) => getIt<SnackbarService>().showError(e.message),
        );
      },
      builder: (context, state) {
        final allContacts = state.data?.contacts ?? [];
        final query = _searchQuery.trim().toLowerCase();
        final contacts = query.isEmpty
            ? allContacts
            : allContacts
                  .where(
                    (c) =>
                        c.displayName.toLowerCase().contains(query) ||
                        c.email.toLowerCase().contains(query),
                  )
                  .toList();

        if (state.isLoading && allContacts.isEmpty) {
          return const AppLoadingIndicator();
        }

        if (allContacts.isEmpty) {
          return AppEmptyState(
            icon: Icons.people_outline_rounded,
            title: context.l10n.noContactsYet,
            subtitle: context.l10n.noContactsYetSubtitle,
            actionLabel: context.l10n.addContact,
            onAction: () => AddContactSheet.show(
              context,
              context.read<ContactCubit>(),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => context.read<ContactCubit>().init(),
          child: ListView(
            padding: const EdgeInsets.only(
              top: AppDimens.md,
              bottom: AppDimens.xxl,
            ),
            children: [
              AppSectionHeader(
                title: context.l10n.yourNetwork,
                subtitle: widget.isPickMode
                    ? context.l10n.chooseRecipient
                    : context.l10n.peopleYouCanPay,
              ),
              const SizedBox(height: AppDimens.md),
              AppTextField(
                controller: _searchController,
                label: context.l10n.searchContacts,
                hintText: context.l10n.searchContacts,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              const SizedBox(height: AppDimens.sm),
              ...contacts.map(
                (contact) => ContactItem(
                  contact: contact,
                  isPickMode: widget.isPickMode,
                  onTap: widget.isPickMode
                      ? () => getIt<NavigationService>().pop(contact)
                      : null,
                  onSendMoney: () => getIt<NavigationService>().push(
                    '/transfer',
                    extra: contact,
                  ),
                  onRequestMoney: () => getIt<NavigationService>().push(
                    '/payment-requests/create',
                    extra: contact,
                  ),
                  onRemove: () => context.read<ContactCubit>().removeContact(
                    contact.uid,
                  ),
                ),
              ),
              if (contacts.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimens.lg),
                  child: Center(child: Text(context.l10n.searchContacts)),
                ),
            ],
          ),
        );
      },
    );
  }
}
