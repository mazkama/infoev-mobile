import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/ev_comparison/controllers/EvCompareController.dart';
import 'package:infoev/app/modules/ev_comparison/views/widgets/ComparisonTable.dart';
import 'package:infoev/app/modules/ev_comparison/views/widgets/EvCard.dart';
import 'package:infoev/app/modules/ev_comparison/views/widgets/VehicleSearchBox.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/modules/ev_comparison/views/widgets/EmptyComparisonView.dart';

class EVComparisonPage extends StatefulWidget {
  const EVComparisonPage({super.key});

  @override
  State<EVComparisonPage> createState() => _EVComparisonPageState();
}

class _EVComparisonPageState extends State<EVComparisonPage> {
  final EVComparisonController controller = Get.put(EVComparisonController());

  final TextEditingController searchControllerA = TextEditingController();
  final TextEditingController searchControllerB = TextEditingController();

  @override
  void dispose() {
    searchControllerA.dispose();
    searchControllerB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0, // Bayangan tetap saat scroll
        backgroundColor: AppColors.cardBackgroundColor,
        title: Text(
          "Comparison Page",
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowMedium.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Kendaraan 1:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    EVSearchField(
                      hintText: 'Cari kendaraan pertama...', 
                      onSelected: controller.selectVehicleA,
                      externalController: searchControllerA,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Kendaraan 2:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    EVSearchField(
                      hintText: 'Cari kendaraan kedua...', 
                      onSelected: controller.selectVehicleB,
                      externalController: searchControllerB,
                    ),
                    if (controller.isLoadingA.value ||
                        controller.isLoadingB.value)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: controller.compareNow,
                          icon: const Icon(Icons.compare_arrows),
                          label: Text(
                            'Compare Sekarang',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                          controller.resetComparison();
                          searchControllerA.clear();
                          searchControllerB.clear();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          ),
                          style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.backgroundSecondary,
                          foregroundColor: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!controller.isCompared.value)
                const EmptyComparisonView(), // Tampilkan tampilan kosong
              if (controller.isCompared.value &&
                  (controller.vehicleA.value != null ||
                      controller.vehicleB.value != null))
                Row(
                  children: [
                    Expanded(
                      child:
                          controller.vehicleA.value != null
                              ? EVCard(vehicle: controller.vehicleA.value!)
                              : const PlaceholderCard(label: 'Kendaraan 1'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          controller.vehicleB.value != null
                              ? EVCard(vehicle: controller.vehicleB.value!)
                              : const PlaceholderCard(label: 'Kendaraan 2'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              if (controller.isCompared.value &&
                  controller.vehicleA.value != null &&
                  controller.vehicleB.value != null)
                ComparisonTable(
                  vehicleA: controller.vehicleA.value,
                  vehicleB: controller.vehicleB.value,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class PlaceholderCard extends StatelessWidget {
  final String label;
  const PlaceholderCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderMedium),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
