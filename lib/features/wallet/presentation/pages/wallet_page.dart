import 'dart:async';

import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_app_bar.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_content.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_skeleton.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, BaseState<User?>>(
      listener: (context, state) {
        state.whenOrNull(
          success: (user) {
            if (user == null) {
              getIt<NavigationService>().go('/login');
              getIt<SnackbarService>().showSuccess(
                context.l10n.signedOutSuccessfully,
              );
            }
          },
          error: (error) => getIt<SnackbarService>().showError(error.message),
        );
      },
      child: BlocBuilder<AuthCubit, BaseState<User?>>(
        builder: (context, authState) {
          final user = authState.data;
          final showVerifyBanner =
              user != null && !user.emailVerified && user.email.isNotEmpty;
          return BlocBuilder<WalletCubit, BaseState<WalletState>>(
            builder: (context, state) {
              return Scaffold(
                appBar: const WalletAppBar(),
                body: SafeArea(
                  child: Column(
                    children: [
                      if (showVerifyBanner) const _EmailVerificationBanner(),
                      Expanded(
                        child: state.when(
                          initial: WalletSkeleton.new,
                          loading: WalletSkeleton.new,
                          error: (error) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: WalletErrorView(
                              title: error.message,
                              onRetry: () =>
                                  context.read<WalletCubit>().loadWallet(),
                            ),
                          ),
                          success: (data) => WalletContent(data: data),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmailVerificationBanner extends StatelessWidget {
  const _EmailVerificationBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.verifyEmailBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<AuthCubit>().sendEmailVerification(),
              child: Text(l10n.verifyEmailResend),
            ),
            TextButton(
              onPressed: () {
                final cubit = context.read<AuthCubit>();
                final snackbar = getIt<SnackbarService>();
                final successTitle = l10n.verifyEmailTitle;
                unawaited(
                  cubit.refreshEmailVerification().then((_) {
                    final user = cubit.state.data;
                    if (user != null && user.emailVerified) {
                      snackbar.showSuccess(successTitle);
                    }
                  }),
                );
              },
              child: Text(l10n.verifyEmailRefresh),
            ),
          ],
        ),
      ),
    );
  }
}
