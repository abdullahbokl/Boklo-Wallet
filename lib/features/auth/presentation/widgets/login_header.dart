import 'package:boklo/shared/theme/tokens/app_spacing.dart';
import 'package:boklo/shared/widgets/atoms/app_text.dart';
import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key,
    this.title = 'Welcome Back',
    this.subtitle = 'Sign in to continue to your wallet',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wallet, size: 64, color: Colors.deepPurple),
        const SizedBox(height: AppSpacing.l),
        AppText.headlineLarge(title),
        const SizedBox(height: AppSpacing.s),
        AppText.bodyMedium(subtitle),
      ],
    );
  }
}
