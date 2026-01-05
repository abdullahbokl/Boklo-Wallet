import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_cubit.dart';
import 'package:boklo/features/transfers/presentation/bloc/transfer_state.dart';
import 'package:boklo/features/transfers/presentation/widgets/transfer_form.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/shared/responsive/responsive_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferPage extends StatelessWidget {
  const TransferPage({super.key});

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
        body: BlocListener<TransferCubit, BaseState<TransferState>>(
          listener: (context, state) {
            if (state.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transfer successful!')),
              );
              Navigator.pop(context, true);
            } else if (state.isError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!.message)),
              );
            }
          },
          child: ResponsiveBuilder(
            mobile: (_, __) => const TransferForm(),
            tablet: (_, __) => const Center(
              child: SizedBox(width: 600, child: TransferForm()),
            ),
            desktop: (_, __) => const Center(
              child: SizedBox(width: 600, child: TransferForm()),
            ),
          ),
        ),
      ),
    );
  }
}
