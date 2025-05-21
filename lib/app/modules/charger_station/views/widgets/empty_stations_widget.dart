import 'package:flutter/material.dart';
import 'package:infoev/app/styles/app_colors.dart';

class EmptyStationsWidget extends StatelessWidget {
  const EmptyStationsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Tambahan penting untuk jaga-jaga
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Bisa diubah ke start jika masih error
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.ev_station_outlined,
              size: 70,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Stasiun tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba cari lokasi lain',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Coba "Jakarta" atau "Surabaya"',
                style: TextStyle(
                  color: AppColors.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
