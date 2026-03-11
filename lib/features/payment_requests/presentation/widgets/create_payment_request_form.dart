import 'dart:async';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePaymentRequestForm extends StatefulWidget {
  const CreatePaymentRequestForm({
    required this.payerIdController,
    required this.amountController,
    required this.noteController,
    required this.isCreating,
    super.key,
  });

  final TextEditingController payerIdController;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final bool isCreating;

  @override
  State<CreatePaymentRequestForm> createState() => _CreatePaymentRequestFormState();
}

class _CreatePaymentRequestFormState extends State<CreatePaymentRequestForm> {
  final _formKey = GlobalKey<FormState>();

  void _onSend(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      unawaited(context.read<PaymentRequestCubit>().createRequest(
        payerId: widget.payerIdController.text,
        amount: double.parse(widget.amountController.text),
        currency: 'USD',
        note: widget.noteController.text,
      ).then((_) {
        if (mounted) {
          getIt<NavigationService>().pop();
          getIt<SnackbarService>().showSuccess('Request Sent');
        }
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: widget.payerIdController,
            label: 'Recipient',
            hintText: 'user@example.com or @username',
            prefixIcon: const Icon(Icons.person_outline),
            suffixIcon: IconButton(
              icon: const Icon(Icons.contacts),
              onPressed: () async {
                final contact = await getIt<NavigationService>()
                    .push<ContactEntity>('/contacts', extra: {'pickMode': true});
                if (contact != null) {
                  setState(() => widget.payerIdController.text = contact.email);
                }
              },
            ),
            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
          ),
          const SizedBox(height: AppDimens.lg),
          AppTextField(
            controller: widget.amountController,
            label: 'Amount',
            hintText: '0.00',
            prefixIcon: const Icon(Icons.attach_money),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) =>
                (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid amount' : null,
          ),
          const SizedBox(height: AppDimens.lg),
          AppTextField(
            controller: widget.noteController,
            label: 'Note (Optional)',
            hintText: 'What is this for?',
            prefixIcon: const Icon(Icons.note_alt_outlined),
          ),
          const SizedBox(height: AppDimens.xxl),
          AppButton(
            text: 'Send Request',
            isLoading: widget.isCreating,
            onPressed: () => _onSend(context),
          ),
        ],
      ),
    );
  }
}
