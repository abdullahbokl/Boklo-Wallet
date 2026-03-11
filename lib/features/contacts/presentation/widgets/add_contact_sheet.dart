import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_cubit.dart';
import 'package:boklo/features/contacts/presentation/bloc/contact_state.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddContactSheet extends StatefulWidget {
  const AddContactSheet({super.key, required this.cubit});
  final ContactCubit cubit;

  static Future<void> show(BuildContext context, ContactCubit cubit) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddContactSheet(cubit: cubit),
    );
  }

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.xl)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: BlocProvider.value(
          value: widget.cubit,
          child: BlocConsumer<ContactCubit, BaseState<ContactState>>(
            listener: (context, state) {
              if (state.data?.isAdding == false) Navigator.pop(context);
            },
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  Text(
                    'Add New Contact',
                    style: AppTypography.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.xxl),
                  AppTextField(
                    controller: _controller,
                    label: 'Email or Username',
                    hintText: 'user@example.com or @username',
                    prefixIcon: const Icon(Icons.person_add_alt_outlined),
                    autofocus: true,
                  ),
                  const SizedBox(height: AppDimens.xl),
                  AppButton(
                    text: 'Add Contact',
                    isLoading: state.data?.isAdding == true,
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        widget.cubit.addContact(_controller.text);
                      }
                    },
                  ),
                  const SizedBox(height: AppDimens.lg),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
