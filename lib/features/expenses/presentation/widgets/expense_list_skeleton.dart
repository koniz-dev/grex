import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/widgets/shimmer_box.dart';

/// Shimmer placeholder for the expense list while data is being fetched.
///
/// Mirrors the visual rhythm of [ExpenseListItem] (description + amount header,
/// payer / participants row, date / split-validity row) so the page does not
/// visually "snap" when real data lands.
class ExpenseListSkeleton extends StatelessWidget {
  /// Creates an [ExpenseListSkeleton].
  const ExpenseListSkeleton({this.itemCount = 5, super.key});

  /// Number of skeleton rows to render. 5 fills a typical phone viewport
  /// without overdrawing.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.page,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 180, height: 16),
                      SizedBox(height: AppSpacing.xs),
                      ShimmerBox(width: 64, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                ShimmerBox(width: 96, height: 20),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                ShimmerBox(width: 120, height: 12),
                Spacer(),
                ShimmerBox(width: 80, height: 12),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                ShimmerBox(width: 90, height: 12),
                Spacer(),
                ShimmerBox(width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
