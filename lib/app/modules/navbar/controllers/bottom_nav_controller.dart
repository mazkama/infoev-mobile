// bottom_nav_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/core/local_db.dart';
import 'package:infoev/app/widgets/login_alert_widget.dart';

class BottomNavController extends GetxController {
  // Current selected tab index
  final RxInt selectedmenu = 0.obs;

  // Simulasi cek login, sebaiknya ambil dari service atau storage token
  bool get isLoggedIn => LocalDB.getToken() != null;

  // Method to change the selected menu
  void changemenuselection(int index) {
    if (index == 2) {
      if (!isLoggedIn) {
        LoginAlertWidget.show(
          title: 'Masuk untuk Melihat Charger Station',
          subtitle: 'Untuk mengakses informasi lokasi charging station, silakan login terlebih dahulu',
          icon: Icons.electric_car_rounded,
        );
        return;
      }
    }
    selectedmenu.value = index;
  }
}
