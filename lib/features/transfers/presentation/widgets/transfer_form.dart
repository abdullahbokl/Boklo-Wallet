import 'dart:async';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/transfers/domain/entities/transfer_entity.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
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
      final transfer = TransferEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID gen
        fromWalletId: fromWalletId,
        toWalletId: _recipientController.text,
        amount: amount,
        currency: currency,
        status: TransferStatus.pending,
        createdAt: DateTime.now(),
      );

      unawaited(
        getIt<NavigationService>().showDialog<void>(
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirm Transfer'),
            content:
                Text('Send $amount $currency to ${_recipientController.text}?'),
            actions: [
              TextButton(
                onPressed: () => getIt<NavigationService>().pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  getIt<NavigationService>().pop();
                  unawaited(
                    context.read<TransferCubit>().createTransfer(transfer),
                  );
                },
                child: const Text('Confirm'),
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
                    getIt<NavigationService>().pop(true);
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
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Balance: ${wallet.balance} ${wallet.currency}',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.l),
                          TextFormField(
                            controller: _recipientController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText:
                                  'Recipient Wallet ID or Alias (BOKLO-XXXX)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          TextFormField(
                            controller: _amountController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final amount = double.tryParse(v);
                              if (amount == null) {
                                return 'Invalid number';
                              }
                              if (amount <= 0) {
                                return 'Amount must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => _onSubmit(wallet.id, wallet.currency),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                  )
                                : const Text('Send Money'),
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
