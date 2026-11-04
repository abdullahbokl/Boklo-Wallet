import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Custom numeric keypad for money entry.
///
/// Produces major-unit strings only: digits and a single '.', capped at
/// two decimals and [maxLength] characters. The decimal separator matches
/// `tryParseMoney` (ASCII '.'), so what the user types is exactly what is
/// parsed. Paste is impossible by construction (the field is read-only),
/// eliminating the most common money-entry mistakes.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    required this.controller,
    this.maxLength = 12,
    super.key,
  });

  final TextEditingController controller;

  /// Maximum characters (including the separator) allowed in the field.
  final int maxLength;

  static const _separator = '.';

  void _append(String digit) {
    var current = controller.text;
    if (current.length >= maxLength) return;

    final hasSeparator = current.contains(_separator);

    if (digit == _separator) {
      if (hasSeparator) return;
      // Leading separator becomes "0.".
      if (current.isEmpty) current = '0';
    } else if (hasSeparator && current.split(_separator).last.length >= 2) {
      // Max two decimal places.
      return;
    }
    if (current == '0' && digit != _separator) {
      current = ''; // avoid "00…"
    }
    controller.text = current + digit;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  void _backspace() {
    final text = controller.text;
    if (text.isEmpty) return;
    controller.text = text.substring(0, text.length - 1);
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final keys = <String?>[
      '1', '2', '3', //
      '4', '5', '6', //
      '7', '8', '9', //
      _separator, '0', null, // null = backspace
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimens.sm,
      crossAxisSpacing: AppDimens.sm,
      childAspectRatio: 2.2,
      children: keys.map((key) {
        if (key == null) {
          return _KeyTile(
            onTap: _backspace,
            child: Icon(Icons.backspace_outlined, color: scheme.onSurface),
          );
        }
        return _KeyTile(
          onTap: () => _append(key),
          child: Text(key, style: AppTypography.headline),
        );
      }).toList(),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}
