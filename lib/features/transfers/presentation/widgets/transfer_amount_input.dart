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
      label: 'Amount',
      hintText: '0.00',
      prefixIcon: const Icon(Icons.attach_money),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final amount = double.tryParse(v);
        if (amount == null) return 'Invalid number';
        if (amount <= 0) return 'Amount must be greater than 0';
        return null;
      },
    );
  }
}
