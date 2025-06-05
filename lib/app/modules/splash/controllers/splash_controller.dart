import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/services/app_token_service.dart';
import 'package:infoev/core/halper.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  late final AppTokenService _appTokenService;

  @override
  void onInit() {
    super.onInit();
    initialiazed();
  }

  void initialiazed() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Inisialisasi AppTokenService cukup dengan base URL backend
    _appTokenService = AppTokenService();
  
    // Ambil atau generate app_key
    final appKey = await _appTokenService.initialize(platform: "android");

    if (appKey == null) {
      // Jika gagal ambil app_key, tampilkan error atau arahkan ke error screen
      debugPrint("Gagal mengambil app_key");
      // Bisa juga arahkan ke halaman error khusus
      Get.snackbar("Error", "Gagal menginisialisasi aplikasi");
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1850));

    // Navigasi ke halaman utama
    Get.offAllNamed(Routes.NAVBAR);
  }
}
