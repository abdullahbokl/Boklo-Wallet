import 'dart:async';

import 'package:boklo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:boklo/shared/theme/tokens/app_radius.dart';
import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/services.dart';
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
            if (wallet.alias != null) ...[
              const SizedBox(height: AppSpacing.m),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wallet.alias!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Monospace',
                          ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    InkWell(
                      onTap: () {
                        unawaited(
                          Clipboard.setData(ClipboardData(text: wallet.alias!)),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alias copied to clipboard'),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
