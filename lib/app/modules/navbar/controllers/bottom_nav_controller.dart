// bottom_nav_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/core/local_db.dart';
import 'package:infoev/app/routes/app_pages.dart';

class BottomNavController extends GetxController {
  // Current selected tab index
  final RxInt selectedmenu = 0.obs;

  // Simulasi cek login, sebaiknya ambil dari service atau storage token
  bool get isLoggedIn => LocalDB.getToken() != null;

  // Method to change the selected menu
  void changemenuselection(int index) {
    if (index == 2) {
      if (!isLoggedIn) {
        Get.bottomSheet(
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.electric_car,
                    color: AppColors.secondaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Masuk untuk Melihat Charger Station',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Untuk mengakses informasi lokasi charging station, silakan login terlebih dahulu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.toNamed(Path.LOGIN);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Login Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                // Cancel Button
                TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Nanti Saja',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          isDismissible: true,
          enableDrag: true,
          backgroundColor: Colors.transparent,
        );
        return;
      }
    }
    selectedmenu.value = index;
  }
}
