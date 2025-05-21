import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

class TrandingCard extends StatelessWidget {
  final String imageUrl;
  final String tag;
  final String time;
  final String title;
  final String author;
  final VoidCallback ontap;

  const TrandingCard({
    super.key,
    required this.imageUrl,
    required this.tag,
    required this.time,
    required this.title,
    required this.author,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        margin: const EdgeInsets.only(
          right: 12,
        ), // Margin sedikit lebih besar untuk pemisahan
        padding: const EdgeInsets.all(10),
        width: 280,
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor, // Abu-abu terang dari palet
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Bayangan lebih halus
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Utama
            ClipRRect(
              borderRadius: BorderRadius.circular(12), // Sudut lebih halus
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: AppColors.cardBackgroundColor,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      height: 160,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.redAccent),
                    ),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),

            // Tag & Time
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       tag,
            //       style: TextStyle(
            //         fontSize: 13,
            //         color: AppColors.secondaryTextColor, // Abu-abu gelap
            //       ),
            //     ),
            //     Text(
            //       time,
            //       style: TextStyle(
            //         fontSize: 13,
            //         color: AppColors.secondaryTextColor,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 8),

            // Judul
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textColor, // Hitam untuk kontras
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Author
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // CircleAvatar(
                //   radius: 10,
                //   backgroundColor:
                //       AppColors.accentColor, // Oranye sebagai aksen
                // ),
                // const SizedBox(width: 8),
                Text(
                  author,
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
