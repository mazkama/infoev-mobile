import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleCarouselCard extends StatelessWidget {
  final String bannerUrl;
  final String name;
  final String brand;
  final VoidCallback onTap;

  const VehicleCarouselCard({
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 4 : 8, // Smaller horizontal margin on tablets
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.cardBackgroundColor.withOpacity(0.95),
                ],
              ),
            ),
            child: Column(
              children: [
                // Image section with enhanced styling
                Expanded(
                  flex:
                      6, // Reduced from 7 to accommodate larger content section
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // colors: [Colors.red.shade50, Colors.red],
                        colors: [AppColors.backgroundSecondary, AppColors.cardBackgroundColor],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topRight,
                                radius: 1.5,
                                colors: [
                                  AppColors.primaryColor.withOpacity(0.03),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Vehicle image
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Center(
                            child: CachedNetworkImage(
                              imageUrl: bannerUrl,
                              maxWidthDiskCache: 500,
                              maxHeightDiskCache: 500,
                              useOldImageOnUrlChange: true,
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
                                      size: 48,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        // Subtle brand badge
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'EV',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content section with modern styling
                Expanded(
                  flex: 4, // Increased content flex to give more space for text
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 20 : 16, // More padding on tablets
                      8, // Reduced top padding
                      isTablet ? 20 : 16,
                      8, // Reduced bottom padding
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.borderLight.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween, // Distribute space evenly
                      children: [
                        // Vehicle info section - no flex, fixed content
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                          ), // Add top padding to move text down
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize:
                                MainAxisSize.min, // Take minimum space needed
                            children: [
                              // Brand name - increased font size
                              Text(
                                brand.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize:
                                      isTablet
                                          ? 13
                                          : 12, // Increased brand font size
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryColor,
                                  letterSpacing: 0.8,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4), // Increased spacing
                              // Vehicle name - increased font size
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize:
                                      isTablet
                                          ? 18
                                          : 16, // Increased vehicle name size
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColor,
                                  height: 1.1, // Slightly looser line height
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Action indicator - no flex, fixed content
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
                          ), // Move up slightly
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lihat Detail',
                                  style: GoogleFonts.poppins(
                                    fontSize:
                                        isTablet ? 15 : 14, // Increased size
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: isTablet ? 15 : 14, // Increased size
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
