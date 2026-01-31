import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
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
import 'package:boklo/shared/responsive/responsive_builder.dart';
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
              getIt<SnackbarService>().showSuccess('Logged out successfully');
            }
          },
          error: (error) {
            getIt<SnackbarService>().showError(error.message);
          },
        );
      },
      child: BlocBuilder<WalletCubit, BaseState<WalletState>>(
        builder: (context, state) {
          return Scaffold(
            appBar: const WalletAppBar(),
            body: state.when(
              initial: () => const WalletSkeleton(),
              loading: () => const WalletSkeleton(),
              error: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: AppDimens.md),
                    Text(error.message),
                    const SizedBox(height: AppDimens.md),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger a retry if available, or just re-emit loading
                        // Ideally Cubit should have a retry method or we assume auto-retry/init
                        // For now just show error
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              success: (data) => ResponsiveBuilder(
                mobile: (context, _) => WalletContent(data: data),
                tablet: (context, _) => Center(
                  child: SizedBox(
                    width: 600,
                    child: WalletContent(data: data),
                  ),
                ),
                desktop: (context, _) => Center(
                  child: SizedBox(
                    width: 800,
                    child: WalletContent(data: data),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
