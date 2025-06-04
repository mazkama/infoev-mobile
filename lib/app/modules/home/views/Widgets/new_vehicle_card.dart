import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class VehicleNewCard extends StatelessWidget {
  final String bannerUrl;
  final String name;
  final String brand;
  final VoidCallback onTap;
  final double width;
  final double imageHeight;

  const VehicleNewCard({
    super.key,
    required this.bannerUrl,
    required this.name,
    required this.brand,
    required this.onTap,
    this.width = 280,
    this.imageHeight = 170,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withAlpha(33),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: bannerUrl,
                cacheKey: bannerUrl,
                maxWidthDiskCache: 500,
                maxHeightDiskCache: 500,
                useOldImageOnUrlChange: true,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                imageBuilder:
                    (context, imageProvider) => Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: AppColors.shimmerBase,
                      highlightColor: AppColors.shimmerHighlight,
                      child: Container(
                        height: imageHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.shimmerBase,
                        ),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppColors.shimmerBase,
                      ),
                      child: const Icon(
                        Icons.error,
                        color: AppColors.errorColor,
                      ),
                    ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withAlpha(153),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
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
  }
}
