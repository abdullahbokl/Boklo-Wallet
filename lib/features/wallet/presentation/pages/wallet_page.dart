import 'dart:async'; // Added for unawaited

import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/domain/entities/user.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/features/wallet/domain/entities/transaction_entity.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:boklo/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:boklo/features/wallet/presentation/widgets/quick_actions_row.dart';
import 'package:boklo/features/wallet/presentation/widgets/transaction_list.dart';
import 'package:boklo/features/wallet/presentation/widgets/wallet_primary_action.dart';
import 'package:boklo/shared/responsive/responsive_builder.dart';
import 'package:boklo/shared/widgets/molecules/balance_card.dart';
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
            appBar: AppBar(
              title: Text(
                'My Wallet',
                style: AppTypography.headline.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              backgroundColor: AppColors.backgroundLight,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
                  child: InkWell(
                    onTap: () {
                      unawaited(context.read<AuthCubit>().logout());
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.md,
                        vertical: AppDimens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: AppTypography.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error) => Center(child: Text(error.message)),
              success: (data) => ResponsiveBuilder(
                mobile: (context, _) => _WalletLayout(data: data),
                tablet: (context, _) => Center(
                  child: SizedBox(
                    width: 600,
                    child: _WalletLayout(data: data),
                  ),
                ),
                desktop: (context, _) => Center(
                  child: SizedBox(
                    width: 800,
                    child: _WalletLayout(data: data),
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

class _WalletLayout extends StatelessWidget {
  const _WalletLayout({required this.data});

  final WalletState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Entrance Animation for Balance Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.9, end: 1),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: BalanceCard(
              balance: data.wallet.balance,
              currency: data.wallet.currency,
              walletId: data.wallet.id,
              alias: data.wallet.alias,
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          // Quick Actions
          WalletPrimaryAction(
            onSendMoney: () async {
              unawaited(getIt<NavigationService>().push('/transfer'));
            },
          ),
          const SizedBox(height: AppDimens.md),
          QuickActionsRow(
            onPaymentRequestsTap: () {
              unawaited(getIt<NavigationService>().push('/payment-requests'));
            },
            onContactsTap: () {
              unawaited(getIt<NavigationService>().push('/contacts'));
            },
            onNotificationsTap: () {
              unawaited(
                getIt<NavigationService>().push('/notification-settings'),
              );
            },
          ),
          const SizedBox(height: AppDimens.xl),
          Text(
            'Recent Transactions',
            style:
                AppTypography.title.copyWith(color: AppColors.textPrimaryLight),
          ),
          const SizedBox(height: AppDimens.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: data.filterType == null,
                  onSelected: (bool selected) {
                    context.read<WalletCubit>().setFilterType(null);
                  },
                ),
                const SizedBox(width: AppDimens.sm),
                FilterChip(
                  label: const Text('Income'),
                  selected: data.filterType == TransactionType.credit,
                  onSelected: (bool selected) {
                    context.read<WalletCubit>().setFilterType(
                          selected ? TransactionType.credit : null,
                        );
                  },
                ),
                const SizedBox(width: AppDimens.sm),
                FilterChip(
                  label: const Text('Expense'),
                  selected: data.filterType == TransactionType.debit,
                  onSelected: (bool selected) {
                    context.read<WalletCubit>().setFilterType(
                          selected ? TransactionType.debit : null,
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.md),
          TransactionList(transactions: data.transactions),
        ],
      ),
    );
  }
}
