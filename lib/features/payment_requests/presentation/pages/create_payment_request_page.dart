import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePaymentRequestPage extends StatefulWidget {
  final String? prefilledPayerId;

  const CreatePaymentRequestPage({super.key, this.prefilledPayerId});

  @override
  State<CreatePaymentRequestPage> createState() =>
      _CreatePaymentRequestPageState();
}

class _CreatePaymentRequestPageState extends State<CreatePaymentRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _payerIdController =
      TextEditingController(); // In real app, separate into User ID input or contact picker
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD'); // Default
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledPayerId != null) {
      _payerIdController.text = widget.prefilledPayerId!;
    }
  }

  @override
  void dispose() {
    _payerIdController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final contact = await getIt<NavigationService>()
        .push<ContactEntity>('/contacts', extra: {'pickMode': true});

    if (contact != null && mounted) {
      setState(() {
        _payerIdController.text = contact.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<PaymentRequestCubit>(), // No init needed for create?
      child: BlocListener<PaymentRequestCubit, BaseState<PaymentRequestState>>(
        listener: (context, state) {
          state.whenOrNull(success: (data) {
            if (!data.isCreating) {
              // Must have finished?
              // Check implies distinct logic in Cubit or just generic success.
              // For MVP, if we emitted success with isCreating=false (after being true), it succeeded.
            }
          }, error: (e) {
            getIt<SnackbarService>().showError(e.message);
          });
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('New Request')),
          body: Padding(
            padding: const EdgeInsets.all(AppDimens.md),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _payerIdController,
                    label: 'Payer ID or Email',
                    hintText: 'User ID or Email',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts),
                      onPressed: _pickContact,
                    ),
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: AppDimens.md),
                  AppTextField(
                    controller: _amountController,
                    label: 'Amount',
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.attach_money),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      if (double.parse(v) <= 0) return 'Must be positive';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.md),
                  AppTextField(
                    controller: _currencyController,
                    label: 'Currency',
                    hintText: 'USD',
                    validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                  ),
                  const SizedBox(height: AppDimens.md),
                  AppTextField(
                    controller: _noteController,
                    label: 'Note (Optional)',
                    hintText: 'What is this for?',
                  ),
                  const Spacer(),
                  BlocBuilder<PaymentRequestCubit,
                          BaseState<PaymentRequestState>>(
                      builder: (context, state) {
                    final isLoading = state.data?.isCreating == true;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context
                                      .read<PaymentRequestCubit>()
                                      .createRequest(
                                        payerId: _payerIdController.text,
                                        amount: double.parse(
                                            _amountController.text),
                                        currency: _currencyController.text,
                                        note: _noteController.text,
                                      )
                                      .then((_) {
                                    // Navigation handling on success
                                    // If no error thrown/emitted
                                    if (context.mounted) {
                                      getIt<NavigationService>().pop();
                                      getIt<SnackbarService>()
                                          .showSuccess('Request Sent');
                                    }
                                  });
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Send Request'),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
