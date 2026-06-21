import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_theme.dart';

class FarmCardShimmer extends StatelessWidget {
  const FarmCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A3A4A) : AppColors.grey200;
    final highlightColor = isDark ? const Color(0xFF3A4A5A) : AppColors.grey100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondary : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 180, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 10),
                  Container(height: 14, width: 120, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(height: 28, width: 60, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(20))),
                      const SizedBox(width: 8),
                      Container(height: 28, width: 50, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(20))),
                      const SizedBox(width: 8),
                      Container(height: 28, width: 70, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(20))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorizontalCardShimmer extends StatelessWidget {
  const HorizontalCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A3A4A) : AppColors.grey200;
    final highlightColor = isDark ? const Color(0xFF3A4A5A) : AppColors.grey100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondary : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 140, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}