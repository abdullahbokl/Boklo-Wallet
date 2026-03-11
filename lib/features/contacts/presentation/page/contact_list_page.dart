import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:boklo/features/contacts/presentation/widgets/add_contact_sheet.dart';
import 'package:boklo/features/contacts/presentation/widgets/contact_item.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:boklo/shared/widgets/molecules/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ContactListPage extends StatelessWidget {
  const ContactListPage({super.key, this.isPickMode = false});
  final bool isPickMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ContactCubit>()..init(),
      child: Container(
        decoration: AppDecorations.mainGradient(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(isPickMode ? 'Select Contact' : 'Contacts', style: AppTypography.headline),
          ),
          floatingActionButton: BlocBuilder<ContactCubit, BaseState<ContactState>>(
            builder: (context, state) => FloatingActionButton(
              onPressed: () => AddContactSheet.show(context, context.read<ContactCubit>()),
              child: const Icon(Icons.person_add_rounded),
            ),
          ),
          body: ResponsiveConstraint(child: _ContactListBody(isPickMode: isPickMode)),
        ),
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
      listener: (context, state) => state.whenOrNull(error: (e) => getIt<SnackbarService>().showError(e.message)),
      builder: (context, state) {
        final contacts = state.data?.contacts ?? [];
        if (state.isLoading && contacts.isEmpty) return const Center(child: CircularProgressIndicator());
        if (contacts.isEmpty) {
          return AppEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No Contacts',
            subtitle: 'Add contacts to send or request money easily.',
            actionLabel: 'Add First Contact',
            onAction: () => AddContactSheet.show(context, context.read<ContactCubit>()),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: [
            const AppSectionHeader(title: 'Your Contacts'),
            const SizedBox(height: AppDimens.md),
            ...contacts.map((c) => ContactItem(
                  contact: c,
                  isPickMode: isPickMode,
                  onTap: isPickMode ? () => getIt<NavigationService>().pop(c) : null,
                  onSendMoney: () => getIt<NavigationService>().push('/transfer', extra: c),
                  onRequestMoney: () => getIt<NavigationService>().push('/payment-requests/create', extra: c),
                  onRemove: () => context.read<ContactCubit>().removeContact(c.uid),
                )),
          ],
        );
      },
    );
  }
}
