import 'package:flutter/material.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        10,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  color: AppColors.shimmerBase,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 15,
                        color: AppColors.textOnPrimary,
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: 150,
                        height: 15,
                        color: AppColors.textOnPrimary,
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: 80,
                        height: 15,
                        color: AppColors.textOnPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
