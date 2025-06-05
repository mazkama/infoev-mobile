import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/ev_comparison/controllers/EvCompareController.dart';
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';
import 'package:infoev/app/modules/ev_comparison/views/widgets/ComparisonTable.dart';
import 'package:infoev/app/modules/ev_comparison/views/widgets/EvCard.dart'; 
import 'package:infoev/app/styles/app_colors.dart'; 
import 'package:shimmer/shimmer.dart';

class EVComparisonPage extends StatefulWidget {
  const EVComparisonPage({super.key});

  @override
  State<EVComparisonPage> createState() => _EVComparisonPageState();
}

class _EVComparisonPageState extends State<EVComparisonPage> {
  final EVComparisonController controller = Get.put(EVComparisonController());

  final TextEditingController searchControllerA = TextEditingController();
  final TextEditingController searchControllerB = TextEditingController();

  // State untuk hasil pencarian
  List<Map<String, dynamic>> searchResultsA = [];
  List<Map<String, dynamic>> searchResultsB = [];

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
        scrolledUnderElevation: 0,
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
              _buildVehicleSelection(
                label: 'Pilih Kendaraan 1',
                selectedVehicle: controller.vehicleA.value,
                onChange: () {
                  controller.vehicleA.value = null;
                  searchControllerA.clear();
                  setState(() => searchResultsA.clear());
                },
                searchController: searchControllerA,
                isLoading:
                    controller.isLoadingA.value || controller.isSearching.value,
                onSearch: (query) async {
                  if (query.isEmpty) {
                    setState(() => searchResultsA.clear());
                  } else {
                    setState(() => searchResultsA = []);
                    final results = await controller.searchVehicles(query);
                    setState(() => searchResultsA = results);
                  }
                },
                searchResults: searchResultsA,
                onSelected: (vehicle) {
                  controller.selectVehicleA(vehicle['slug']);
                  searchControllerA.text =
                      '${vehicle['brand']['name']} ${vehicle['name']}';
                  setState(() => searchResultsA.clear());
                },
              ),
              _buildVehicleSelection(
                label: 'Pilih Kendaraan 2',
                selectedVehicle: controller.vehicleB.value,
                onChange: () {
                  controller.vehicleB.value = null;
                  searchControllerB.clear();
                  setState(() => searchResultsB.clear());
                },
                searchController: searchControllerB,
                isLoading:
                    controller.isLoadingB.value || controller.isSearching.value,
                onSearch: (query) async {
                  if (query.isEmpty) {
                    setState(() => searchResultsB.clear());
                  } else {
                    setState(() => searchResultsB = []);
                    final results = await controller.searchVehicles(query);
                    setState(() => searchResultsB = results);
                  }
                },
                searchResults: searchResultsB,
                onSelected: (vehicle) {
                  controller.selectVehicleB(vehicle['slug']);
                  searchControllerB.text =
                      '${vehicle['brand']['name']} ${vehicle['name']}';
                  setState(() => searchResultsB.clear());
                },
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
              const SizedBox(height: 24),
              // if (!controller.isCompared.value)
              //   const EmptyComparisonView(), // Tampilkan tampilan kosong
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

  Widget _buildVehicleSelection({
    required String label,
    required VehicleModel? selectedVehicle,
    required VoidCallback onChange,
    required TextEditingController searchController,
    required bool isLoading,
    required Function(Map<String, dynamic>) onSelected,
    required List<Map<String, dynamic>> searchResults,
    required Function(String) onSearch,
    String subtitle = 'Cari dan pilih kendaraan listrik untuk membandingkan',
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondaryColor,
                      AppColors.secondaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_car_filled_outlined,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          selectedVehicle != null
              ? _buildSelectedVehicleCard(
                vehicle: selectedVehicle,
                onChange: onChange,
              )
              : _buildVehicleSelectionButton(
                controller: searchController,
                isLoading: isLoading,
                onSearch: onSearch,
                searchResults: searchResults,
                onSelected: onSelected,
                isTablet: isTablet,
              ),
        ],
      ),
    );
  }

  Widget _buildSelectedVehicleCard({
    required VehicleModel vehicle,
    required VoidCallback onChange,
  }) {
    final imageUrl = vehicle.thumbnailUrl;
    final brandName = vehicle.brand;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (imageUrl.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.shimmerBase,
                        highlightColor: AppColors.shimmerHighlight,
                        child: Container(color: Colors.white),
                      ),
                  errorWidget:
                      (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppColors.secondaryColor,
                size: 40,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brandName,
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  vehicle.name,
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChange,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.change_circle_outlined,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionButton({
    required TextEditingController controller,
    required bool isLoading,
    required Function(String) onSearch,
    required List<Map<String, dynamic>> searchResults,
    required Function(Map<String, dynamic>) onSelected,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.backgroundSecondary,
                  AppColors.backgroundSecondary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderMedium.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Row(
                children: [
                  // Search icon with background
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryColor,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text field and content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controller,
                          style: GoogleFonts.poppins(
                            color: AppColors.textColor,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari kendaraan listrik...',
                            hintStyle: GoogleFonts.poppins(
                              color: AppColors.textTertiary,
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: onSearch,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketik nama atau merek kendaraan',
                          style: GoogleFonts.poppins(
                            color: AppColors.textTertiary.withOpacity(0.8),
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Clear button or indicator
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        isLoading
                            ? Container(
                              key: const ValueKey('loading'),
                              padding: const EdgeInsets.all(8),
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondaryColor,
                                ),
                              ),
                            )
                            : controller.text.isNotEmpty
                            ? Container(
                              key: const ValueKey('clear'),
                              child: InkWell(
                                onTap: () {
                                  controller.clear();
                                  onSearch('');
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: AppColors.errorColor,
                                    size: isTablet ? 20 : 16,
                                  ),
                                ),
                              ),
                            )
                            : Container(
                              key: const ValueKey('arrow'),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary,
                                size: isTablet ? 24 : 20,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Hasil pencarian DIBAWAH search field
        if (searchResults.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            constraints: const BoxConstraints(maxHeight: 400),
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: searchResults.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(color: AppColors.dividerColor, height: 1),
              itemBuilder: (context, index) {
                final vehicle = searchResults[index];
                final imageUrl = vehicle['thumbnail_url'] ?? '';
                final brandName = vehicle['brand']?['name'] ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading:
                      imageUrl.isNotEmpty
                          ? Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder:
                                    (context, url) => Shimmer.fromColors(
                                      baseColor: AppColors.shimmerBase,
                                      highlightColor:
                                          AppColors.shimmerHighlight,
                                      child: Container(
                                        color: AppColors.shimmerBase,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: AppColors.secondaryColor,
                                        size: 24,
                                      ),
                                    ),
                              ),
                            ),
                          )
                          : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: AppColors.secondaryColor,
                              size: 30,
                            ),
                          ),
                  title: Text(
                    vehicle['name'] ?? '',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    brandName,
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => onSelected(vehicle),
                );
              },
            ),
          ),
      ],
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
