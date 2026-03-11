import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionFilters extends StatelessWidget {
  const TransactionFilters({required this.data, super.key});

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: data.filterType == null,
            onSelected: (bool selected) {
              context.read<WalletCubit>().setFilterType(null);
            },
          ),
          const SizedBox(width: AppDimens.sm),
          FilterChip(
            label: const Text('Income'),
            selected: data.filterType == TransactionType.credit,
            onSelected: (bool selected) {
              context.read<WalletCubit>().setFilterType(
                    selected ? TransactionType.credit : null,
                  );
            },
          ),
          const SizedBox(width: AppDimens.sm),
          FilterChip(
            label: const Text('Expense'),
            selected: data.filterType == TransactionType.debit,
            onSelected: (bool selected) {
              context.read<WalletCubit>().setFilterType(
                    selected ? TransactionType.debit : null,
                  );
            },
          ),
        ],
      ),
    );
  }
}
