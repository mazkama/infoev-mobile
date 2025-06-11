import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/services/ConfigService.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  size: 100.sp,
                  color: AppColors.buttonPrimary,
                ),
                SizedBox(height: 32.h),
                Image.asset(
                  'assets/images/logo_infoev.png',
                  height: 80.h,
                ),
                SizedBox(height: 24.h),
                Text(
                  'Sedang Dalam Perbaikan',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Kami sedang meningkatkan layanan untuk pengalaman yang lebih baik. Silakan coba beberapa saat lagi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 40.h),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Tampilkan loading indicator
                    Get.dialog(
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                      barrierDismissible: false,
                    );
                    
                    // Coba refresh konfigurasi
                    bool success = await ConfigService().refreshConfig();
                    
                    // Tutup dialog loading
                    Get.back();
                    
                    if (success && !ConfigService().isInMaintenanceMode) {
                      // Jika berhasil dan tidak dalam maintenance mode, navigasi ke route awal
                      Get.offAllNamed('/');
                    } else {
                      // Tampilkan pesan error
                      Get.snackbar(
                        'Masih Dalam Perbaikan',
                        'Aplikasi masih dalam pemeliharaan. Silakan coba beberapa saat lagi.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}