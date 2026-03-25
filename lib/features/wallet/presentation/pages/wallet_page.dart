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
              getIt<SnackbarService>().showSuccess('Signed out successfully.');
            }
          },
          error: (error) => getIt<SnackbarService>().showError(error.message),
        );
      },
      child: BlocBuilder<WalletCubit, BaseState<WalletState>>(
        builder: (context, state) {
          return Scaffold(
            appBar: const WalletAppBar(),
            body: SafeArea(
              child: state.when(
                initial: WalletSkeleton.new,
                loading: WalletSkeleton.new,
                error: (error) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: WalletErrorView(
                    title: error.message,
                    onRetry: () => context.read<WalletCubit>().loadWallet(),
                  ),
                ),
                success: (data) => WalletContent(data: data),
              ),
            ),
          );
        },
      ),
    );
  }
}
