import 'package:flutter/material.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerVehicleCarousel extends StatelessWidget {
  const ShimmerVehicleCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    // Responsive height to match carousel
    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = screenHeight < 600 ? 260.0 : 280.0;
    
    return Container(
      height: carouselHeight, // Match the responsive carousel height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0), // No horizontal padding
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width - 32, // Full width minus margins
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Match carousel margin
            child: Shimmer.fromColors(
              baseColor: AppColors.shimmerBase,
              highlightColor: AppColors.shimmerHighlight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Image shimmer - maintain 7:3 ratio from real card
                    Expanded(
                      flex: 7,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.shimmerBase,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    // Content shimmer
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), // Match card padding
                        decoration: const BoxDecoration(
                          color: AppColors.shimmerBase,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 12,
                              color: AppColors.shimmerHighlight,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: AppColors.shimmerHighlight,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 120,
                              height: 16,
                              color: AppColors.shimmerHighlight,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: AppColors.shimmerHighlight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
