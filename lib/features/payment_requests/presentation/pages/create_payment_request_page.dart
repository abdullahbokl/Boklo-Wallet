import 'package:boklo/config/theme/app_decorations.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/create_payment_request_form.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:boklo/shared/widgets/atoms/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePaymentRequestPage extends StatefulWidget {
  const CreatePaymentRequestPage({super.key, this.prefilledPayerId});
  final String? prefilledPayerId;

  @override
  State<CreatePaymentRequestPage> createState() => _CreatePaymentRequestPageState();
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
                listener: (context, state) => state.whenOrNull(
                  error: (e) => getIt<SnackbarService>().showError(e.message),
                ),
                builder: (context, state) => AppCard(
                  child: CreatePaymentRequestForm(
                    payerIdController: _payerIdController,
                    amountController: _amountController,
                    noteController: _noteController,
                    isCreating: state.data?.isCreating == true,
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
