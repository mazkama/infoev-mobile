import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class VehiclePopulerCard extends StatelessWidget {
  final String bannerUrl;
  final String name;
  final String brand;
  final VoidCallback onTap;

  const VehiclePopulerCard({
    super.key,
    required this.bannerUrl,
    required this.name,
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardWidth = isTablet ? 180.0 : 160.0;
    final imageHeight = isTablet ? 100.0 : 85.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.only(right: isTablet ? 16 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  AppColors.cardBackgroundColor.withOpacity(0.98),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern image section with gradient overlay
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey.shade50, Colors.white],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topRight,
                              radius: 1.2,
                              colors: [
                                AppColors.primaryColor.withOpacity(0.02),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Vehicle image
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: bannerUrl,
                            cacheKey: bannerUrl,
                            maxWidthDiskCache: 200,
                            maxHeightDiskCache: 200,
                            useOldImageOnUrlChange: true,
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 200),
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: AppColors.shimmerBase,
                                  highlightColor: AppColors.shimmerHighlight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.shimmerBase,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.electric_car_outlined,
                                    color: AppColors.primaryColor.withOpacity(
                                      0.5,
                                    ),
                                    size: isTablet ? 36 : 32,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Modern content section
                Expanded(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 16 : 14,
                      isTablet ? 12 : 10,
                      isTablet ? 16 : 14,
                      isTablet ? 14 : 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Vehicle info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Brand name
                            Text(
                              brand.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 11 : 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryColor,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Vehicle name
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 15 : 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textColor,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        // Modern action indicator
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lihat Detail',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 12 : 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: isTablet ? 12 : 11,
                                color: AppColors.primaryColor,
                              ),
                            ],
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
      ),
    );
  }
}
