import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting header skeleton
          _SkeletonBox(width: 200, height: 32),
          const SizedBox(height: 8),
          _SkeletonBox(width: 150, height: 16),
          
          const SizedBox(height: 32),
          
          // Start Training button skeleton
          _SkeletonBox(width: double.infinity, height: 58, borderRadius: 18),
          
          const SizedBox(height: 24),
          
          // Stats grid skeleton
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 100, borderRadius: 20)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 100, borderRadius: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonBox(width: double.infinity, height: 100, borderRadius: 20)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 100, borderRadius: 20)),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Movement quality skeleton
          _SkeletonBox(width: double.infinity, height: 200, borderRadius: 24),
          
          const SizedBox(height: 24),
          
          // Weekly insight skeleton
          _SkeletonBox(width: double.infinity, height: 80, borderRadius: 24),
          
          const SizedBox(height: 32),
          
          // Recent workouts skeleton
          _SkeletonBox(width: 150, height: 24),
          const SizedBox(height: 16),
          _SkeletonBox(width: double.infinity, height: 120, borderRadius: 20),
          const SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 120, borderRadius: 20),
          const SizedBox(height: 12),
          _SkeletonBox(width: double.infinity, height: 120, borderRadius: 20),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
