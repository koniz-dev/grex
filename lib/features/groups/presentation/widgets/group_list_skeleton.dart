import 'package:flutter/material.dart';
import 'package:grex/shared/theme/app_elevation.dart';
import 'package:grex/shared/theme/app_radius.dart';
import 'package:grex/shared/theme/app_spacing.dart';
import 'package:grex/shared/widgets/shimmer_box.dart';

/// Skeleton placeholder for the group list while groups are being fetched.
///
/// Renders a fixed number of cards whose silhouettes mirror `GroupListItem`
/// (avatar + two text lines + chevron). This is more truthful to the
/// upcoming layout than a spinner, so the page doesn't visibly "reshuffle"
/// when data lands.
class GroupListSkeleton extends StatelessWidget {
  /// Creates a [GroupListSkeleton].
  const GroupListSkeleton({this.itemCount = 6, super.key});

  /// How many skeleton rows to render. 6 is enough to fill a phone viewport
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
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            ShimmerBox(
              width: 48,
              height: 48,
              shape: BoxShape.circle,
              borderRadius: null,
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 160),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerBox(width: 100, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            ShimmerBox(width: 16),
          ],
        ),
      ),
    );
  }
}
