import 'dart:async';
import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePaymentRequestPage extends StatefulWidget {
  const CreatePaymentRequestPage({super.key, this.prefilledPayerId});
  final String? prefilledPayerId;

  @override
  State<CreatePaymentRequestPage> createState() => _CreatePaymentRequestPageState();
}

class _CreatePaymentRequestPageState extends State<CreatePaymentRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _payerIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPayerId != null) _payerIdController.text = widget.prefilledPayerId!;
  }

  @override
  void dispose() {
    _payerIdController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSend(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      unawaited(context.read<PaymentRequestCubit>().createRequest(
        payerId: _payerIdController.text,
        amount: double.parse(_amountController.text),
        currency: 'USD',
        note: _noteController.text,
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
    return BlocProvider(
      create: (context) => getIt<PaymentRequestCubit>(),
      child: Container(
        decoration: AppDecorations.mainGradient(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('New Request', style: AppTypography.headline),
          ),
          body: ResponsiveConstraint(
            maxWidth: 500,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.lg),
              child: BlocConsumer<PaymentRequestCubit, BaseState<PaymentRequestState>>(
                listener: (context, state) => state.whenOrNull(error: (e) => getIt<SnackbarService>().showError(e.message)),
                builder: (context, state) => AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _payerIdController,
                          label: 'Recipient',
                          hintText: 'user@example.com or @username',
                          prefixIcon: const Icon(Icons.person_outline),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.contacts),
                            onPressed: () async {
                              final contact = await getIt<NavigationService>().push<ContactEntity>('/contacts', extra: {'pickMode': true});
                              if (contact != null) setState(() => _payerIdController.text = contact.email);
                            },
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                        const SizedBox(height: AppDimens.lg),
                        AppTextField(
                          controller: _amountController,
                          label: 'Amount',
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.attach_money),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid amount' : null,
                        ),
                        const SizedBox(height: AppDimens.lg),
                        AppTextField(
                          controller: _noteController,
                          label: 'Note (Optional)',
                          hintText: 'What is this for?',
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                        ),
                        const SizedBox(height: AppDimens.xxl),
                        AppButton(
                          text: 'Send Request',
                          isLoading: state.data?.isCreating == true,
                          onPressed: () => _onSend(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
