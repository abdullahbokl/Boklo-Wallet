import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/shared/theme/tokens/app_radius.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class WalletBalanceCard extends StatelessWidget {
  final WalletEntity wallet;
  final bool isLoading;

  const WalletBalanceCard({
    super.key,
    required this.wallet,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              '${wallet.currency} ${wallet.balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
