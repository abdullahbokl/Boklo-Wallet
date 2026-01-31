import 'dart:async';

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_confirmation_dialog.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_form_content.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferForm extends StatefulWidget {
  final String? prefilledRecipient;

  const TransferForm({super.key, this.prefilledRecipient});

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledRecipient != null) {
      _recipientController.text = widget.prefilledRecipient!;
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSubmit(String fromWalletId, String currency) {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final recipient = _recipientController.text;

      unawaited(
        getIt<NavigationService>().showDialog<void>(
          builder: (dialogContext) => TransferConfirmationDialog(
            amount: amount,
            currency: currency,
            recipient: recipient,
            onConfirm: () {
              unawaited(
                context.read<TransferCubit>().createTransfer(
                      fromWalletId: fromWalletId,
                      recipient: recipient,
                      amount: amount,
                      currency: currency,
                    ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletCubit, BaseState<WalletState>>(
      builder: (context, walletState) {
        return walletState.maybeWhen(
          success: (data) {
            final wallet = data.wallet;
            return BlocListener<TransferCubit, BaseState<TransferState>>(
              listener: (context, state) {
                state.whenOrNull(
                  success: (_) {
                    getIt<SnackbarService>().showSuccess('Transfer successful');
                    getIt<NavigationService>().go('/wallet');
                  },
                  error: (error) {
                    getIt<SnackbarService>().showError(error.message);
                  },
                );
              },
              child: BlocBuilder<TransferCubit, BaseState<TransferState>>(
                builder: (context, transferState) {
                  return TransferFormContent(
                    formKey: _formKey,
                    wallet: wallet,
                    recipientController: _recipientController,
                    amountController: _amountController,
                    isLoading: transferState.isLoading,
                    onSubmit: () => _onSubmit(wallet.id, wallet.currency),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          orElse: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_off,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppDimens.md),
                Text(
                  'Failed to load wallet',
                  style: AppTypography.title.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppDimens.md),
                ElevatedButton.icon(
                  onPressed: () {
                    unawaited(context.read<WalletCubit>().loadWallet());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
