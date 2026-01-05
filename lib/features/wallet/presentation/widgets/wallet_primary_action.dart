import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class WalletPrimaryAction extends StatelessWidget {
  const WalletPrimaryAction({
    required this.onSendMoney,
    super.key,
  });

  final VoidCallback onSendMoney;

  @override
  Widget build(BuildContext context) {
    // Layout decision: Using SizedBox(width: double.infinity) to make the button
    // span the full available width, increasing touch target and visibility.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onSendMoney,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send Money'),
          // Layout decision: large padding for easier tapping and visual hierarchy.
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          ),
        ),
      ),
    );
  }
}
