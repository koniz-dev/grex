import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/widgets/shimmer_box.dart';

/// Shimmer placeholder for the balance page while data is being fetched.
///
/// Renders a stylised summary card followed by a small list of member rows so
/// the layout doesn't visually snap when real balances land.
class BalanceListSkeleton extends StatelessWidget {
  /// Creates a [BalanceListSkeleton].
  const BalanceListSkeleton({this.itemCount = 5, super.key});

  /// Number of skeleton list rows to render.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.page,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const _SummarySkeleton(),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < itemCount; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _RowSkeleton(),
          ),
      ],
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 160, height: 18),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 56)),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: ShimmerBox(height: 56)),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 56)),
                SizedBox(width: AppSpacing.lg),
                Expanded(child: ShimmerBox(height: 56)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            ShimmerBox(
              width: 40,
              height: 40,
              shape: BoxShape.circle,
              borderRadius: null,
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140),
                  SizedBox(height: AppSpacing.xs),
                  ShimmerBox(width: 90, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShimmerBox(width: 70),
                SizedBox(height: AppSpacing.xs),
                ShimmerBox(width: 50, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
