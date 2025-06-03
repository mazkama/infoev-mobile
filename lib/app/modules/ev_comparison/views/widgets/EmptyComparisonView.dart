import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/styles/app_colors.dart';

class EmptyComparisonView extends StatelessWidget {
  const EmptyComparisonView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppColors.secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Belum ada kendaraan yang dibandingkan',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan pilih kendaraan untuk memulai perbandingan.',
              style: GoogleFonts.poppins(
                color: AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
