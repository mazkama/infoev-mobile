import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

class NewsTitle extends StatelessWidget {
  final String imageUrl;
  final String tag;
  final String time;
  final String title;
  final String author;
  final VoidCallback ontap;

  const NewsTitle({
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
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 12), // Margin konsisten dengan TrandingCard
        decoration: BoxDecoration(
          color: AppColors.backgroundColor, // Abu-abu terang dari palet
          borderRadius: BorderRadius.circular(12), // Sudut lebih halus, konsisten dengan TrandingCard
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Bayangan halus
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // Sesuaikan dengan borderRadius container
                color: AppColors.backgroundColor, // Putih untuk latar belakang gambar
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.cardBackgroundColor,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.redAccent),
                  ),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12), // Spacing sedikit lebih besar untuk kejelasan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   tag,
                    //   style: TextStyle(
                    //     color: AppColors.secondaryTextColor, // Abu-abu gelap
                    //     fontSize: 12,
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textColor, // Hitam untuk kontras
                        fontWeight: FontWeight.w600, // Sesuaikan dengan TrandingCard
                        fontSize: 18,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // CircleAvatar(
                        //   radius: 10,
                        //   backgroundColor: AppColors.accentColor, // Oranye sebagai aksen
                        // ),
                        // const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            author,
                            style: TextStyle(
                              color: AppColors.primaryColor,  
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: AppColors.secondaryTextColor, // Abu-abu gelap
                            fontSize: 12,
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
      ),
    );
  }
}