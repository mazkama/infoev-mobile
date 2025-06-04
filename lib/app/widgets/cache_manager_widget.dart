import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/services/cache_service.dart';
import 'package:infoev/app/styles/app_colors.dart';

class CacheManagerController extends GetxController {
  var cacheInfo = {}.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCacheInfo();
  }

  Future<void> loadCacheInfo() async {
    isLoading.value = true;
    try {
      final info = await CacheService.getCacheInfo();
      cacheInfo.value = info;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load cache info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAllCache() async {
    try {
      Get.dialog(
        AlertDialog(
          title: Text(
            'Clear All Cache',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'This will clear all cached data and the app will need to fetch fresh data from the server. Continue?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                isLoading.value = true;
                
                await CacheService.clearAllCache();
                await loadCacheInfo();
                
                Get.snackbar(
                  'Success',
                  'All cache cleared successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear cache: $e');
    }
  }

  Future<void> cleanExpiredCache() async {
    try {
      isLoading.value = true;
      await CacheService.cleanExpiredCache();
      await loadCacheInfo();
      Get.snackbar(
        'Success',
        'Expired cache cleaned successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to clean expired cache: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class CacheManagerWidget extends StatelessWidget {
  final CacheManagerController controller = Get.put(CacheManagerController());

  CacheManagerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cache Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.cardBackgroundColor,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadCacheInfo,
          color: AppColors.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cache Statistics Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache Statistics',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                        'Total Cache Entries',
                        '${controller.cacheInfo['totalKeys'] ?? 0}',
                        Icons.storage,
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Valid Cache',
                        '${controller.cacheInfo['validCacheCount'] ?? 0}',
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Expired Cache',
                        '${controller.cacheInfo['expiredCacheCount'] ?? 0}',
                        Icons.error,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildStatRow(
                        'Cache Size',
                        '${controller.cacheInfo['approximateSizeKB'] ?? 0} KB',
                        Icons.folder_outlined,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Cache Actions Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cache Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Clean Expired Cache Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.cleanExpiredCache,
                          icon: const Icon(Icons.cleaning_services),
                          label: Text(
                            'Clean Expired Cache',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Clear All Cache Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: controller.clearAllCache,
                          icon: const Icon(Icons.delete_forever),
                          label: Text(
                            'Clear All Cache',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Cache Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About Cache',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cache helps improve app performance by storing data locally. Clearing cache will require the app to fetch fresh data from the server, which may temporarily slow down loading times.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textColor,
          ),
        ),
      ],
    );
  }
}
