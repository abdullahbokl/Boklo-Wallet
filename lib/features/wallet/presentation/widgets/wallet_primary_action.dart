import 'package:flutter/material.dart';
import '../../../../config/theme/app_dimens.dart';
import '../../../../shared/widgets/atoms/app_button.dart';

class WalletPrimaryAction extends StatelessWidget {
  const WalletPrimaryAction({
    required this.onSendMoney,
    super.key,
  });

  final VoidCallback onSendMoney;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.md),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          onPressed: onSendMoney,
          text: 'Send Money',
          icon: Icons.send_rounded,
        ),
      ),
    );
  }
}
