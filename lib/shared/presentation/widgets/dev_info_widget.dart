import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/core/config/emulator_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget that displays debug information like User ID, Wallet ID, and Environment.
/// This widget is automatically hidden in Release mode.
class DevInfoWidget extends StatelessWidget {
  final String? userId;
  final String? walletId;
  final String? region;

  const DevInfoWidget({
    super.key,
    this.userId,
    this.walletId,
    this.region,
  });

  @override
  Widget build(BuildContext context) {
    // Strictly hide in Release mode
    final isEmulator = EmulatorConfig.resolvedHost != null;

    // Strictly hide in Release mode OR if not using Emulators
    if (kReleaseMode || !isEmulator) {
      return const SizedBox.shrink();
    }

    final envLabel = 'DEBUG / EMULATOR';
    final envColor = AppColors.textSecondaryLight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: envColor.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, size: 12, color: envColor),
              const SizedBox(width: 4),
              Text(
                'DEVELOPER MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: envColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildRow('ENV', envLabel, valueColor: envColor),
          if (userId != null) _buildRow('UID', userId!),
          if (walletId != null) _buildRow('WID', walletId!),
          if (region != null)
            _buildRow('RGN', region!)
          else
            _buildRow('RGN', 'us-central1 (default)'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 10,
            color: valueColor ?? AppColors.textSecondaryLight,
            fontFamily: 'Courier',
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
