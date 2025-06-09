import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/calculator/controllers/CalculatorController.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  final CalculatorController controller = Get.put(CalculatorController());
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _dailyDistanceController =
      TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Set nilai default untuk input
    _priceController.text = controller.electricityPrice.value.toStringAsFixed(
      0,
    );
    _dailyDistanceController.text = controller.dailyDistance.value
        .toStringAsFixed(0);

    // Listen to search state changes
    ever(controller.isSearching, (bool isSearching) {
      if (isSearching) {
        // Schedule focus for next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).requestFocus(_searchFocusNode);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _priceController.dispose();
    _dailyDistanceController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textColor,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
          },
        ),
        title: Text(
          "Kalkulator EV",
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // AppBar
            // _buildAppBar(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Hitung perkiraan biaya penggunaan kendaraan listrik berdasarkan konsumsi energi dan harga listrik di daerah Anda.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Vehicle selection
                        _buildVehicleSelection(),
                        const SizedBox(height: 24),

                        // Electricity price input
                        _buildElectricityPriceInput(),
                        const SizedBox(height: 32),

                        // Calculation results
                        _buildCalculationResults(),

                        // Disclaimer
                        const SizedBox(height: 24),
                        _buildDisclaimer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelection() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Container(
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
          // Modern Header Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
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
                      'Pilih Kendaraan Listrik',
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cari dan pilih kendaraan listrik untuk perhitungan',
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

          // Selection button or selected vehicle card
          Obx(
            () =>
                controller.selectedVehicle.value != null
                    ? _buildSelectedVehicleCard()
                    : _buildVehicleSelectionButton(),
          ),

          // Search results
          Obx(() {
            if (controller.isSearching.value) {
              return Column(
                children: [
                  SizedBox(height: isTablet ? 16 : 12),
                  _buildSearchResults()
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionButton() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: () {
          controller.toggleSearch();
          FocusScope.of(context).requestFocus(_searchFocusNode);
        },
        borderRadius: BorderRadius.circular(16),
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
          child: Stack(
            children: [
              // Background pattern/decoration
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.02),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              
              // Main content
              Padding(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                child: Row(
                  children: [
                    // Search icon with background
                    Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.primaryColor,
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
                            controller: _searchController,
                            focusNode: _searchFocusNode,
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
                            onChanged: (value) {
                              if (!controller.isSearching.value) {
                                controller.toggleSearch();
                              }

                              if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
                              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  controller.performSearch(value);
                                }
                              });
                            },
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
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: value.text.isNotEmpty
                              ? Container(
                                  key: const ValueKey('clear'),
                                  child: InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      controller.resetSearch();
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorColor.withOpacity(0.1),
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
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedVehicleCard() {
    final vehicle = controller.selectedVehicle.value!;
    final imageUrl = vehicle['thumbnail_url'] ?? '';
    final brandName = vehicle['brand']?['name'] ?? '';

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
          // Vehicle Image
          if (imageUrl.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color:
                    AppColors
                        .cardBackgroundColor, // Background putih untuk gambar PNG
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain, // Mengubah fit menjadi contain
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

          // Vehicle Info
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
                  vehicle['name'] ?? '',
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(
                  () =>
                      controller.batteryCapacity.value > 0
                          ? Text(
                            'Baterai: ${controller.batteryCapacity.value} kWh',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Change button
          GestureDetector(
            onTap: () {
              setState(() {
                _searchController.clear(); // Clear search text
              });
              controller.selectedVehicle.value = null; // Reset selected vehicle
              controller.searchResults
                  .clear(); // Clear search results without showing empty state
              // First set searching to true, but delay focus to next frame to ensure text field is rendered
              controller.isSearching.value = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                }
              });
            },
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

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.isSearchLoading.value) {
        return _buildLoadingState();
      }

      if (controller.hasError.value) {
        return _buildErrorState();
      }

      if (controller.searchResults.isEmpty) {
        // Only show "no results" if there's text in the search field AND we've actually performed a search
        if (_searchController.text.isNotEmpty && controller.hasSearched.value) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Tidak ada hasil ditemukan',
                style: GoogleFonts.poppins(
                  color: AppColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink(); // Don't show anything if search is empty or we haven't searched yet
      }

      // Tampilkan hasil pencarian kendaraan
      final vehicles = controller.searchResults['KENDARAAN'] ?? [];

      if (vehicles.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'Tidak ada kendaraan ditemukan',
              style: GoogleFonts.poppins(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        constraints: const BoxConstraints(maxHeight: 400),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          shrinkWrap: true,
          itemCount: vehicles.length,
          separatorBuilder:
              (context, index) =>
                  Divider(color: AppColors.dividerColor, height: 1),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
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
                                  highlightColor: AppColors.shimmerHighlight,
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
              onTap: () {
                controller.selectVehicle(vehicle);
                FocusScope.of(context).unfocus();
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Terjadi kesalahan',
            style: GoogleFonts.poppins(
              color: AppColors.errorColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.red[300], fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              controller.performSearch(_searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: Text('Coba Lagi', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildElectricityPriceInput() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Container(
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
          // Daily Distance Section
          _buildModernInputSection(
            title: 'Rata-rata Berkendara per Hari',
            icon: Icons.route_outlined,
            iconColor: AppColors.primaryColor,
            child: _buildModernDistanceInput(isTablet),
          ),

          SizedBox(height: isTablet ? 32 : 28),

          // Electricity Price Section
          _buildModernInputSection(
            title: 'Harga Listrik per kWh',
            icon: Icons.electrical_services_outlined,
            iconColor: AppColors.secondaryColor,
            child: _buildModernPriceInput(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInputSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isTablet ? 24 : 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),
        child,
      ],
    );
  }

  Widget _buildModernDistanceInput(bool isTablet) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderMedium.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // KM prefix
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 14,
                  vertical: isTablet ? 18 : 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'KM',
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),

              // Text field
              Expanded(
                child: TextField(
                  controller: _dailyDistanceController,
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 18 : 16,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '30',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textTertiary,
                      fontSize: isTablet ? 16 : 14,
                    ),
                    suffixIcon: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 18 : 16,
                      ),
                      child: Text(
                        'per hari',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final distance = double.tryParse(value) ?? controller.dailyDistance.value;
                      controller.updateDailyDistance(distance);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 20 : 16),

        // Modern Slider
        Obx(() => _buildModernSlider(
          value: controller.dailyDistanceSlider.value.clamp(1, 500),
          min: 1,
          max: 500,
          divisions: 499,
          label: '${controller.dailyDistanceSlider.value.toStringAsFixed(0)} KM',
          minLabel: '1 KM',
          maxLabel: '500 KM',
          onChanged: (value) {
            controller.updateDailyDistance(value);
            _dailyDistanceController.text = value.toStringAsFixed(0);
          },
          isTablet: isTablet,
        )),
      ],
    );
  }

  Widget _buildModernPriceInput(bool isTablet) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderMedium.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Rp prefix
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 14,
                  vertical: isTablet ? 18 : 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'Rp',
                  style: GoogleFonts.poppins(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),

              // Text field
              Expanded(
                child: TextField(
                  controller: _priceController,
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 18 : 16,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '1445',
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textTertiary,
                      fontSize: isTablet ? 16 : 14,
                    ),
                    suffixIcon: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 18 : 16,
                      ),
                      child: Text(
                        'per kWh',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final price = double.tryParse(value) ?? controller.electricityPrice.value;
                      controller.updateElectricityPrice(price);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 20 : 16),

        // Modern Slider
        Obx(() => _buildModernSlider(
          value: controller.sliderValue.value.clamp(900, 2600),
          min: 900,
          max: 2600,
          divisions: 34,
          label: 'Rp ${controller.sliderValue.value.toStringAsFixed(0)}',
          minLabel: 'Rp 900',
          maxLabel: 'Rp 2.600',
          onChanged: (value) {
            controller.updateElectricityPrice(value);
            _priceController.text = value.toStringAsFixed(0);
          },
          isTablet: isTablet,
        )),
      ],
    );
  }

  Widget _buildModernSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<double> onChanged,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryColor,
              inactiveTrackColor: AppColors.borderMedium.withOpacity(0.3),
              thumbColor: AppColors.primaryColor,
              overlayColor: AppColors.primaryColor.withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: isTablet ? 14 : 12,
              ),
              overlayShape: RoundSliderOverlayShape(
                overlayRadius: isTablet ? 24 : 20,
              ),
              trackHeight: isTablet ? 6 : 4,
              valueIndicatorColor: AppColors.primaryColor,
              valueIndicatorTextStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ),
          
          SizedBox(height: isTablet ? 8 : 4),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minLabel,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  maxLabel,
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationResults() {
    return Obx(() {
      // Only show results if a vehicle is selected
      if (controller.selectedVehicle.value == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.infoColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.infoColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih kendaraan untuk melihat hasil perhitungan',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.infoColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.borderMedium,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Perhitungan',
              style: GoogleFonts.poppins(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Cost per kilometer
            _buildResultItem(
              icon: Icons.route,
              title: 'Biaya per Kilometer',
              value: 'Rp ${_formatNumber(controller.costPerKm.value)}',
              subtitle: 'Per km perjalanan',
            ),

            const Divider(color: Colors.grey, height: 32),

            // Cost per 100km
            _buildResultItem(
              icon: Icons.speed,
              title: 'Biaya per 100 Kilometer',
              value: 'Rp ${_formatNumber(controller.costPer100Km.value)}',
              subtitle: 'Per 100 km perjalanan',
            ),

            const Divider(color: Colors.grey, height: 32),

            // Full charge cost
            _buildResultItem(
              icon: Icons.ev_station,
              title: 'Biaya Pengisian Penuh',
              value: 'Rp ${_formatNumber(controller.fullChargeCost.value)}',
              subtitle: 'Untuk sekali pengisian penuh',
            ),

            const Divider(color: Colors.grey, height: 32),

            // Daily running cost
            _buildResultItem(
              icon: Icons.today,
              title: 'Biaya Harian',
              value: 'Rp ${_formatNumber(controller.dailyRunningCost.value)}',
              subtitle:
                  'Untuk ${controller.dailyDistance.value.toStringAsFixed(0)} km/hari',
            ),

            const Divider(color: Colors.grey, height: 32),

            // Monthly cost
            _buildResultItem(
              icon: Icons.calendar_month,
              title: 'Biaya Bulanan (estimasi)',
              value: 'Rp ${_formatNumber(controller.costPerMonth.value)}',
              subtitle: 'Selama 30 hari',
            ),

            const Divider(color: Colors.grey, height: 32),

            // Range per charge
            _buildResultItem(
              icon: Icons.battery_charging_full,
              title: 'Jarak Tempuh per Pengisian',
              value: '${controller.rangePerCharge.value.toStringAsFixed(0)} km',
              subtitle: 'Dengan baterai penuh',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildResultItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.secondaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: AppColors.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Disclaimer',
                style: GoogleFonts.poppins(
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Perhitungan ini hanya perkiraan dan dapat berbeda dengan penggunaan sebenarnya. Hasil aktual dapat bervariasi tergantung pada berbagai faktor seperti kondisi jalan, gaya mengemudi, suhu, dan penggunaan AC.',
            style: GoogleFonts.poppins(
              color: AppColors.secondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Format numbers with commas as separators
  String _formatNumber(double number) {
    if (number < 1) {
      return number.toStringAsFixed(2);
    }

    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
  }
}
