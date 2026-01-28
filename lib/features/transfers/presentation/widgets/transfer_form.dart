import 'dart:async';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/config/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferForm extends StatefulWidget {
  const TransferForm({super.key});

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();

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
          builder: (dialogContext) => AlertDialog(
            title: Text('Confirm Transfer', style: AppTypography.headline),
            content: Text(
              'Send $amount $currency to $recipient?',
              style: AppTypography.bodyMedium,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
            actions: [
              TextButton(
                onPressed: () => getIt<NavigationService>().pop(),
                child: Text('Cancel',
                    style: AppTypography.label
                        .copyWith(color: AppColors.textSecondaryLight)),
              ),
              TextButton(
                onPressed: () {
                  getIt<NavigationService>().pop();
                  unawaited(
                    context.read<TransferCubit>().createTransfer(
                          fromWalletId: fromWalletId,
                          recipient: recipient,
                          amount: amount,
                          currency: currency,
                        ),
                  );
                },
                child: Text('Confirm',
                    style:
                        AppTypography.label.copyWith(color: AppColors.primary)),
              ),
            ],
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
                    // Navigate back to the wallet (home) screen
                    getIt<NavigationService>().go('/wallet');
                  },
                  error: (error) {
                    getIt<SnackbarService>().showError(error.message);
                  },
                );
              },
              child: BlocBuilder<TransferCubit, BaseState<TransferState>>(
                builder: (context, transferState) {
                  final isLoading = transferState.isLoading;

                  return Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.md),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimens.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusLg),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.1)),
                              boxShadow: AppColors.shadowSm,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Available Balance',
                                  style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondaryLight),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${wallet.currency} ${wallet.balance.toStringAsFixed(2)}',
                                  style: AppTypography.headline
                                      .copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimens.xl),
                          AppTextField(
                            controller: _recipientController,
                            enabled: !isLoading,
                            label: 'Recipient',
                            hintText: 'Wallet ID, Alias, or Email',
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppDimens.md),
                          AppTextField(
                            controller: _amountController,
                            enabled: !isLoading,
                            label: 'Amount',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.attach_money),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final amount = double.tryParse(v);
                              if (amount == null) return 'Invalid number';
                              if (amount <= 0)
                                return 'Amount must be greater than 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppDimens.xl),
                          SizedBox(
                            height: 56, // Large touch target
                            child: AppButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _onSubmit(wallet.id, wallet.currency),
                              text: 'Confirm Transfer',
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          orElse: () => const Center(child: Text('Failed to load wallet')),
        );
      },
    );
  }
}
