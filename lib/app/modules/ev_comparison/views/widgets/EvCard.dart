import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class EVCard extends StatelessWidget {
  final VehicleModel vehicle;

  const EVCard({super.key, required this.vehicle});

  String? getHighlightValue(String type) {
    final spec = vehicle.highlightSpecs.firstWhere(
      (s) => s.type == type,
      orElse: () => HighlightSpec(type: type, value: null, unit: null),
    );

    if (spec.value == null) return null;
    return '${spec.value} ${spec.unit ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final image = vehicle.thumbnailUrl;

    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.cardBackgroundColor, // Background putih
                child: CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.shimmerBase,
                        highlightColor: AppColors.shimmerHighlight,
                        child: Container(color: AppColors.shimmerBase),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: AppColors.cardBackgroundColor,
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
                ),
              ),
            ),
          ),
          // Informasi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.name}',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Highlight Specs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _specColumn(
                          Icons.speed,
                          "Kecepatan",
                          getHighlightValue("maxSpeed"),
                          iconColor: AppColors.secondaryColor,
                        ),
                      ),
                      Expanded(
                        child: _specColumn(
                          Icons.ev_station,
                          "Jarak",
                          getHighlightValue("range"),
                          iconColor: AppColors.secondaryColor,
                        ),
                      ),
                      Expanded(
                        child: _specColumn(
                          Icons.bolt,
                          "Isi Ulang",
                          getHighlightValue("charge"),
                          iconColor: AppColors.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specColumn(
    IconData icon,
    String label,
    String? value, {
    Color? iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? AppColors.secondaryColor, size: 26),
          const SizedBox(height: 6),
          Text(
            value ?? "-",
            style: GoogleFonts.poppins(
              color: AppColors.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
