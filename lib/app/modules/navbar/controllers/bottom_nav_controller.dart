// bottom_nav_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import 'package:infoev/core/local_db.dart';
import 'package:infoev/app/routes/app_pages.dart';

class BottomNavController extends GetxController {
  // Current selected tab index
  final RxInt selectedmenu = 0.obs;

  // Simulasi cek login, sebaiknya ambil dari service atau storage token
  bool get isLoggedIn => LocalDB.getToken() != null;

  // Method to change the selected menu
  void changemenuselection(int index) {
    if (index == 2) { // ChargerStationPage
      if (!isLoggedIn) {
        // Jika belum login, tampilkan pesan dan arahkan ke halaman login
        Get.snackbar(
          'Akses Ditolak',
          'Anda harus login terlebih dahulu untuk mengakses Charger Station',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        // Navigasi ke halaman login
        Get.toNamed(Path.LOGIN);
        return; // jangan lanjut ganti tab
      }
    }

    // Ganti tab jika tidak ada kondisi khusus
    selectedmenu.value = index;
  }
} 