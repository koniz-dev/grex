import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/widgets/shimmer_box.dart';

/// Shimmer placeholder for the payment list while data is being fetched.
///
/// Mirrors the visual rhythm of `PaymentListItem` (payer → recipient header,
/// optional description, amount, and date / delete-button row) so the page
/// does not visually snap when real data lands.
class PaymentListSkeleton extends StatelessWidget {
  /// Creates a [PaymentListSkeleton].
  const PaymentListSkeleton({this.itemCount = 5, super.key});

  /// Number of skeleton rows to render. 5 fills a typical phone viewport
  /// without overdrawing.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.page,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, _) => const Padding(
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
    return const Card(
      elevation: AppElevation.card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 200),
                      SizedBox(height: AppSpacing.xs),
                      ShimmerBox(width: 140, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                ShimmerBox(width: 80, height: 20),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                ShimmerBox(width: 90, height: 12),
                Spacer(),
                ShimmerBox(width: 32, height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
