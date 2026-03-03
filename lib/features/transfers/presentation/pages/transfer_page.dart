import 'dart:async';

import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_form.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferPage extends StatelessWidget {
  final String? prefilledRecipient;

  const TransferPage({super.key, this.prefilledRecipient});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TransferCubit>()),
        BlocProvider(
          create: (_) {
            final cubit = getIt<WalletCubit>();
            unawaited(cubit.loadWallet());
            return cubit;
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Money')),
        body: ResponsiveConstraint(
          child: TransferForm(prefilledRecipient: prefilledRecipient),
        ),
      ),
    );
  }
}
