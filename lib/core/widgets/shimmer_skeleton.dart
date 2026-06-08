import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_constants.dart';

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      period: AppConstants.shimmerDuration,
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class JobCardSkeleton extends StatelessWidget {
  const JobCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerSkeleton(width: 48, height: 48, borderRadius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerSkeleton(width: double.infinity, height: 18),
                      SizedBox(height: 8),
                      ShimmerSkeleton(width: 120, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ShimmerSkeleton(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            const ShimmerSkeleton(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}

class JobListSkeleton extends StatelessWidget {
  const JobListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (_, _) => const JobCardSkeleton(),
    );
  }
}
