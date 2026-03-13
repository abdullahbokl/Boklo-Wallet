import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/shared/widgets/atoms/app_shimmer.dart';
import 'package:boklo/shared/widgets/molecules/balance_card.dart';
import 'package:flutter/material.dart';

class WalletSkeleton extends StatelessWidget {
  const WalletSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // One Shimmer to rule them all: Synchronizes animation and saves CPU
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ensure BalanceCard handles its own 'isLoading' internally
            // with simple DecoratedBoxes to avoid double-shimmering.
            const BalanceCard(
              balance: 0,
              currency: '',
              isLoading: true,
            ),
            const SizedBox(height: AppDimens.lg),

            // Quick Actions: Use Row + List.generate with DecoratedBox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (_) => const _SkeletonBox(size: 70)),
            ),

            const SizedBox(height: AppDimens.xl),

            // Title Skeleton
            const _SkeletonLine(width: 150, height: 20),

            const SizedBox(height: AppDimens.md),

            // Transaction List
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) =>
                    const _TransactionItemSkeleton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Use private helper widgets with 'const' to flatten the main tree
/// and allow Flutter to cache these elements.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _TransactionItemSkeleton extends StatelessWidget {
  const _TransactionItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppDimens.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration:
                BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: SizedBox.square(dimension: 48),
          ),
          SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: double.infinity, height: 14),
                SizedBox(height: 8),
                _SkeletonLine(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
