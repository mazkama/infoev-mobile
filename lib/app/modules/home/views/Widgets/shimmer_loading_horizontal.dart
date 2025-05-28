import 'package:flutter/material.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingHorizontal extends StatelessWidget {
  const ShimmerLoadingHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // Naikkan tinggi jika diperlukan
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Shimmer.fromColors(
              baseColor: AppColors.shimmerBase,
              highlightColor: AppColors.shimmerHighlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140, // Naikkan lebar jika diinginkan
                    height: 140, // Naikkan tinggi container utama
                    color: AppColors.shimmerBase,
                  ),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 15, color: AppColors.textOnPrimary),
                  const SizedBox(height: 5),
                  Container(width: 70, height: 15, color: AppColors.textOnPrimary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
