import 'dart:async';

import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_form.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({
    super.key,
    this.prefilledRecipient,
  });

  final String? prefilledRecipient;

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
      child: const _TransferScreen(),
    );
  }
}

class _TransferScreen extends StatelessWidget {
  const _TransferScreen();

  @override
  Widget build(BuildContext context) {
    final transferPage = context.findAncestorWidgetOfExactType<TransferPage>();
    return AppPageScaffold(
      title: 'Send money',
      child: TransferForm(
        prefilledRecipient: transferPage?.prefilledRecipient,
      ),
    );
  }
}
