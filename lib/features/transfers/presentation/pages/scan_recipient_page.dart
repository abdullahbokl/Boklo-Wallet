import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/features/wallet/domain/services/pay_me_payload.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR scanner for pay-me codes.
///
/// Pops with the decoded recipient identifier (String), or null if the
/// user dismisses. Non-Boklo QR content is rejected with a message.
class ScanRecipientPage extends StatefulWidget {
  const ScanRecipientPage({super.key});

  @override
  State<ScanRecipientPage> createState() => _ScanRecipientPageState();
}

class _ScanRecipientPageState extends State<ScanRecipientPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final recipient = PayMePayload.decode(raw);
      if (recipient == null) {
        _handled = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.qrInvalidCode)),
        );
        Navigator.of(context).pop();
        return;
      }
      _handled = true;
      Navigator.of(context).pop(recipient);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.qrScan),
        actions: [
          IconButton(
            tooltip: context.l10n.qrTorch,
            icon: const Icon(Icons.flashlight_on_rounded),
            onPressed: () => unawaited(_controller.toggleTorch()),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.xxl),
              child: Text(
                context.l10n.qrScanHint,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
