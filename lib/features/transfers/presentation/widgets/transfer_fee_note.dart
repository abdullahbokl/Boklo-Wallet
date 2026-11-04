import 'dart:async';

import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/features/transfers/domain/repositories/transfer_repository.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/utils/money.dart';
import 'package:flutter/material.dart';

/// Live server-quoted fee line under the amount field.
///
/// Quotes are debounced while the user types and hidden entirely when the
/// fee schedule is disabled (fee == 0) or the quote fails — the send
/// remains authoritative server-side regardless.
class TransferFeeNote extends StatefulWidget {
  const TransferFeeNote({
    required this.amountController,
    required this.currency,
    super.key,
  });

  final TextEditingController amountController;
  final String currency;

  @override
  State<TransferFeeNote> createState() => _TransferFeeNoteState();
}

class _TransferFeeNoteState extends State<TransferFeeNote> {
  Timer? _debounce;
  int? _feeMinor;
  String? _quotedFor;

  @override
  void initState() {
    super.initState();
    widget.amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.amountController.removeListener(_onAmountChanged);
    super.dispose();
  }

  void _onAmountChanged() {
    _debounce?.cancel();
    final raw = widget.amountController.text;
    if (raw.isEmpty) {
      if (mounted) {
        setState(() {
          _feeMinor = null;
          _quotedFor = null;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_quote(raw));
    });
  }

  Future<void> _quote(String raw) async {
    final amountMinor = tryParseMoney(raw);
    if (amountMinor == null) return;
    if (_quotedFor == raw && _feeMinor != null) return;

    final result = await getIt<TransferRepository>().estimateTransferFee(
      amountMinor,
    );
    if (!mounted) return;
    result.fold(
      (_) {},
      (feeMinor) {
        setState(() {
          _feeMinor = feeMinor;
          _quotedFor = raw;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fee = _feeMinor;
    if (fee == null || fee <= 0) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.sm),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 16, color: scheme.primary),
          const SizedBox(width: AppDimens.xs4),
          Text(
            context.l10n.feeLine(fee.moneyLabel(widget.currency)),
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
