import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/features/transfers/presentation/widgets/amount_keypad.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: controller,
          // Keypad-only entry: the field mirrors keypad output and is not
          // directly editable, so pasting arbitrary text is impossible.
          readOnly: true,
          enabled: enabled,
          label: context.l10n.amount,
          hintText: context.l10n.amountHint,
          prefixIcon: const Icon(Icons.attach_money),
          validator: (v) {
            if (v == null || v.isEmpty) return context.l10n.required;
            final amount = double.tryParse(v);
            if (amount == null) return context.l10n.invalidNumber;
            if (amount <= 0) return context.l10n.amountMustBePositive;
            return null;
          },
        ),
        const SizedBox(height: AppDimens.lg),
        AbsorbPointer(
          absorbing: !enabled,
          child: AmountKeypad(controller: controller),
        ),
      ],
    );
  }
}
