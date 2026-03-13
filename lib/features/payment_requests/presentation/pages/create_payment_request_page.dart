import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/create_payment_request_form.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePaymentRequestPage extends StatefulWidget {
  const CreatePaymentRequestPage({
    super.key,
    this.prefilledPayerId,
  });

  final String? prefilledPayerId;

  @override
  State<CreatePaymentRequestPage> createState() =>
      _CreatePaymentRequestPageState();
}

class _CreatePaymentRequestPageState extends State<CreatePaymentRequestPage> {
  final _payerIdController = TextEditingController();
  final _amountController = TextEditingController();
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
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentRequestCubit>(),
      child: AppPageScaffold(
        title: 'New request',
        maxWidth: 500,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          child: BlocConsumer<PaymentRequestCubit, BaseState<PaymentRequestState>>(
            listener: (context, state) {
              state.whenOrNull(
                error: (e) => getIt<SnackbarService>().showError(e.message),
              );
            },
            builder: (context, state) {
              return AppCard(
                padding: const EdgeInsets.all(24),
                child: CreatePaymentRequestForm(
                  payerIdController: _payerIdController,
                  amountController: _amountController,
                  noteController: _noteController,
                  isCreating: state.data?.isCreating ?? false,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
