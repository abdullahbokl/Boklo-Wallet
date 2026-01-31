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
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow('ENV', 'DEBUG / EMULATOR'),
          if (userId != null) _buildRow('UID', userId!),
          if (walletId != null) _buildRow('WID', walletId!),
          if (region != null) _buildRow('RGN', region!),
          if (region == null) _buildRow('RGN', 'us-central1 (default)'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 10,
            color: Colors.red,
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
