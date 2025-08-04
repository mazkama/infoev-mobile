import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/services/app_token_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  late final AppTokenService _appTokenService;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService();
    // Pastikan spinner muncul dulu, baru inisialisasi berjalan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialiazed();
    });
  }

  void initialiazed() async {
    isLoading.value = true;

    String? appKey;
    try {
      appKey = await _appTokenService.initialize(platform: "android");
    } catch (e) {
      appKey = null;
      debugPrint("Error handshake: $e");
    }

    if (appKey == null) {
      isLoading.value = false;
      await Future.delayed(const Duration(milliseconds: 100));
      Get.defaultDialog(
        title: "Koneksi Gagal",
        middleText: "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.",
        textConfirm: "Coba Lagi",
        onConfirm: () async {
          Get.back();
          await Future.delayed(const Duration(milliseconds: 300));
          await _appTokenService.deleteAppKey();
          initialiazed();
        },
        barrierDismissible: false,
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    isLoading.value = false;
    Get.offAllNamed(Routes.NAVBAR);
  }
}
