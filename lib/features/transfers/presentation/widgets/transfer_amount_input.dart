import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';

class TransferAmountInput extends StatelessWidget {
  const TransferAmountInput({
    required this.controller,
    required this.enabled,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      enabled: enabled,
      label: context.l10n.amount,
      hintText: context.l10n.amountHint,
      prefixIcon: const Icon(Icons.attach_money),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return context.l10n.required;
        final amount = double.tryParse(v);
        if (amount == null) return context.l10n.invalidNumber;
        if (amount <= 0) return context.l10n.amountMustBePositive;
        return null;
      },
    );
  }
}
