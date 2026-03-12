import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionFilters extends StatelessWidget {
  const TransactionFilters({
    required this.data,
    super.key,
  });

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            selected: data.filterType == null,
            onTap: () => context.read<WalletCubit>().setFilterType(null),
          ),
          const SizedBox(width: AppDimens.sm),
          _FilterPill(
            label: 'Income',
            selected: data.filterType == TransactionType.credit,
            onTap: () => context.read<WalletCubit>().setFilterType(
                  data.filterType == TransactionType.credit
                      ? null
                      : TransactionType.credit,
                ),
          ),
          const SizedBox(width: AppDimens.sm),
          _FilterPill(
            label: 'Expense',
            selected: data.filterType == TransactionType.debit,
            onTap: () => context.read<WalletCubit>().setFilterType(
                  data.filterType == TransactionType.debit
                      ? null
                      : TransactionType.debit,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.md,
          vertical: AppDimens.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
