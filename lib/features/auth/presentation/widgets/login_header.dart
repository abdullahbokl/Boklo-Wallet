import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_dimens.dart';
import '../../../../config/theme/app_typography.dart';

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
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppDimens.lg),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.shadowLg,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.xl),
        Text(
          title,
          style:
              AppTypography.display.copyWith(color: AppColors.textPrimaryLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.xs),
        Text(
          subtitle,
          style: AppTypography.bodyLarge
              .copyWith(color: AppColors.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
