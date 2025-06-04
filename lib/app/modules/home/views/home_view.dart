import 'package:infoev/app/modules/favorite_vehicles/views/FavoriteVehiclesPage.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_vehicle_populer.dart';
import 'package:infoev/app/modules/home/views/Widgets/vehicle_populer_card.dart';
import 'package:infoev/app/modules/home/views/Widgets/vehicle_carousel_card.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_vehicle_carousel.dart';
import 'package:infoev/app/modules/navbar/controllers/bottom_nav_controller.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/news/controllers/news_controller.dart';
import 'package:infoev/app/modules/home/views/Widgets/news_title.dart';
import 'package:infoev/app/modules/news/views/news_detail_view.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_loading.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/explore/model/MerekModel.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final MerekController controller = Get.find<MerekController>();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  bool _shouldAutoFocus = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final newQuery = _searchController.text;
      if (newQuery != _lastSearchQuery) {
        _lastSearchQuery = newQuery;
        if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted && _searchFocusNode.hasFocus) {
            controller.performSearch(newQuery);
          }
        });
      }
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        _debounceTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static final NewsController newsController = Get.put(NewsController());

  Future<void> _onRefresh() async {
    await newsController.loadAllData();
  }

  Widget _buildSearchAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        color: AppColors.cardBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
              onPressed: () {
                controller.resetSearch();
                controller
                    .resetFilters(); // Reset filter saat tombol back diklik
                _searchController.clear();
              },
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.poppins(color: AppColors.textColor),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari kendaraan listrik...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.primaryColor,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              controller.searchBrands('');
                              controller.performSearch('');
                            },
                          )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
                onChanged: (value) {
                  if (_debounceTimer?.isActive ?? false)
                    _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      controller.searchBrands(value);
                      controller.performSearch(value);
                    }
                  });
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    // Clear search field before navigation
                    _searchController.clear();
                    _lastSearchQuery = '';

                    // Navigate to search results page when user presses enter
                    // Mark this as manual search (not from history)
                    Get.toNamed(
                      '/search-results',
                      parameters: {
                        'query': value.trim(),
                        'fromManualSearch': 'true',
                      },
                    );
                  }
                },
                autofocus: _shouldAutoFocus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.isSearchLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
          ),
        );
      }

      if (_searchController.text.isEmpty) {
        return _buildSearchHistory();
      }

      if (controller.searchResults.isEmpty) {
        return Center(
          child: Text(
            'Tidak ditemukan hasil',
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
              fontSize: 16,
            ),
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final entry = controller.searchResults.entries.elementAt(index);
          final sectionTitle = entry.key;
          final items = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  sectionTitle,
                  style: GoogleFonts.poppins(
                    color: AppColors.secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...items.map((item) {
                if (sectionTitle == 'MEREK') {
                  final brand = item as MerekModel;
                  return _buildBrandSearchItem(brand);
                } else {
                  return _buildVehicleSearchItem(item);
                }
              }).toList(),
              if (index < controller.searchResults.length - 1)
                const Divider(color: AppColors.dividerColor),
            ],
          );
        },
      );
    });
  }

  Widget _buildSearchHistory() {
    return Obx(() {
      if (controller.searchHistory.isEmpty) {
        return Center(
          child: Text(
            'Belum ada riwayat pencarian',
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
              fontSize: 16,
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Pencarian',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.clearSearchHistory(),
                  child: Text(
                    'Hapus Semua',
                    style: GoogleFonts.poppins(
                      color: AppColors.secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.searchHistory.length,
              itemBuilder: (context, index) {
                final query = controller.searchHistory[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(
                    Icons.history,
                    color: AppColors.textSecondary,
                  ),
                  title: Text(
                    query,
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                      fontSize: 14,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => controller.removeFromSearchHistory(query),
                  ),
                  onTap: () {
                    // Dismiss keyboard before navigation
                    FocusScope.of(context).unfocus();

                    // Set flag to prevent autofocus when returning
                    _shouldAutoFocus = false;

                    // Clear search field and navigate to SearchResultsPage
                    _searchController.clear();
                    _lastSearchQuery = '';

                    // Navigate to SearchResultsPage when selecting from search history
                    Get.toNamed(
                      '/search-results',
                      parameters: {'query': query, 'fromManualSearch': 'false'},
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBrandSearchItem(MerekModel brand) {
    // Get background color from controller configuration
    final backgroundColor = controller.getBrandBackgroundColor(brand.name);

    return InkWell(
      onTap: () {
        Get.toNamed(
          '/brand/${brand.id}',
          parameters: {'brandId': brand.id.toString()},
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (brand.banner != null)
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: brand.banner!,
                    fit: BoxFit.contain,
                    placeholder:
                        (context, url) => Shimmer.fromColors(
                          baseColor: AppColors.shimmerBase,
                          highlightColor: AppColors.shimmerHighlight,
                          child: Container(color: backgroundColor),
                        ),
                    errorWidget:
                        (context, url, error) => const Icon(
                          Icons.error_outline,
                          color: AppColors.primaryColor,
                        ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.electric_car,
                  color: AppColors.textSecondary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${brand.vehiclesCount} kendaraan',
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSearchItem(Map<String, dynamic> vehicle) {
    return InkWell(
      onTap: () {
        Get.toNamed('/kendaraan/${vehicle['slug']}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48, // Square ratio 48x48
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white, // White background for transparent images
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: vehicle['thumbnail_url'] ?? '',
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) => Shimmer.fromColors(
                        baseColor: AppColors.shimmerBase,
                        highlightColor: AppColors.shimmerHighlight,
                        child: Container(color: Colors.white),
                      ),
                  errorWidget:
                      (context, url, error) => const Icon(
                        Icons.error_outline,
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['name'] ?? '',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (vehicle['brand'] != null)
                    Text(
                      vehicle['brand']['name'] ?? '',
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    initializeDateFormatting('id_ID', null);
    return Obx(
      () => Scaffold(
        appBar:
            controller.isSearching.value
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: _buildSearchAppBar(),
                )
                : AppBar(
                  backgroundColor:
                      AppColors
                          .cardBackgroundColor, // Gunakan ungu tua dari palet
                  scrolledUnderElevation: 0, // Bayangan tetap saat scroll
                  title: InkWell(
                    onTap: () {
                      // Aksi saat logo ditekan (opsional)
                      // newsController.getNewsInfoEv();
                    },
                    child: Image.asset(
                      'assets/images/logo_infoev.png', // Logo dari assets
                      height: 20, // Sesuaikan ukuran logo
                      fit: BoxFit.contain,
                    ),
                  ),
                  centerTitle: false, // Pastikan logo berada di tengah
                  actions: [
                    IconButton(
                      onPressed: () {
                        // Aksi saat ikon love ditekan (opsional)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritVehiclesPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.favorite_border, // Ikon hati (kosong)
                        color:
                            AppColors.primaryColor, // Warna putih untuk kontras
                        size: 25, // Ukuran ikon
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Aksi saat ikon search ditekan
                        // TODO: Navigasi ke halaman pencarian atau tampilkan dialog search
                        controller.toggleSearch();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _searchFocusNode.requestFocus();
                        });
                      },
                      icon: const Icon(
                        Icons.search, // Ikon search
                        color: AppColors.primaryColor,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 8), // Padding di sebelah kanan ikon
                  ],
                ),
        backgroundColor: AppColors.backgroundColor, // Latar belakang putih
        body:
            controller.isSearching.value
                ? _buildSearchResults()
                : Padding(
                  padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.accentColor,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Modern centered title with enhanced styling
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "Kendaraan Populer",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColors.textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor,
                                        AppColors.secondaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ), // Modern Carousel for Popular Vehicles
                          Obx(() {
                            if (newsController.isLoading.value) {
                              return const ShimmerVehicleCarousel();
                            } else {
                              // Responsive height calculation
                              final screenHeight =
                                  MediaQuery.of(context).size.height;
                              final carouselHeight =
                                  screenHeight < 600
                                      ? 260.0
                                      : 280.0; // Smaller height on smaller screens

                              return CarouselSlider.builder(
                                itemCount:
                                    newsController.popularVehiclesList.length,
                                options: CarouselOptions(
                                  height:
                                      carouselHeight, // Responsive height to accommodate shadows
                                  viewportFraction:
                                      1.0, // Full width to prevent showing adjacent cards
                                  enlargeCenterPage:
                                      false, // Disable enlargement
                                  autoPlay: true,
                                  autoPlayInterval: const Duration(seconds: 4),
                                  autoPlayAnimationDuration: const Duration(
                                    milliseconds: 800,
                                  ),
                                  autoPlayCurve: Curves.easeInOutCubic,
                                  scrollDirection: Axis.horizontal,
                                  enableInfiniteScroll:
                                      newsController
                                          .popularVehiclesList
                                          .length >
                                      1,
                                  padEnds: false, // Remove default padding
                                ),
                                itemBuilder: (context, index, realIndex) {
                                  final e =
                                      newsController.popularVehiclesList[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 20,
                                    ), // Margins for shadow space
                                    child: VehicleCarouselCard(
                                      onTap: () {
                                        Get.toNamed('/kendaraan/${e.slug}');
                                      },
                                      bannerUrl: e.thumbnailUrl,
                                      name: e.name,
                                      brand: e.brand?.name ?? 'InfoEV.id',
                                    ),
                                  );
                                },
                              );
                            }
                          }),

                          const SizedBox(
                            height: 20,
                          ), // Spacing lebih besar untuk pemisahan
                          // Modern centered title with enhanced styling for "Kendaraan Terbaru"
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  "Kendaraan Terbaru",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColors.textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor,
                                        AppColors.secondaryColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Modern horizontal list for "Kendaraan Terbaru"
                          Obx(() {
                            if (newsController.isLoading.value) {
                              return const ShimmerVehiclePopuler();
                            } else {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isTablet = screenWidth > 600;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ), // Reduced margin for better spacing
                                height:
                                    isTablet
                                        ? 220.0
                                        : 200.0, // Reduced height to make cards shorter
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount:
                                      newsController.newVehiclesList.length,
                                  itemBuilder: (context, index) {
                                    final e =
                                        newsController.newVehiclesList[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        left: index == 0 ? 4 : 0,
                                        right: 12,
                                        top: 12, // Add top spacing for shadow
                                        bottom:
                                            15, // Add bottom spacing for shadow
                                      ),
                                      child: VehiclePopulerCard(
                                        onTap: () {
                                          Get.toNamed('/kendaraan/${e.slug}');
                                        },
                                        bannerUrl: e.thumbnailUrl,
                                        name: e.name,
                                        brand: e.brand?.name ?? 'InfoEV.id',
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          }),

                          const SizedBox(
                            height: 30,
                          ), // Spacing lebih besar untuk pemisahan
                          // Modern Action Cards Row
                          Row(
                            children: [
                              // Charger Stations Card
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.put(
                                      BottomNavController(
                                    ).changemenuselection(2));
                                  },
                                  child: Container(
                                    height:
                                        MediaQuery.of(context).size.width > 600
                                            ? 140
                                            : 120,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.primaryColor.withOpacity(
                                            0.1,
                                          ),
                                          AppColors.secondaryColor.withOpacity(
                                            0.05,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.shadowMedium
                                              .withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            // TODO: Replace with custom image
                                            // Optimal image size: 48x48 px (white background)
                                            // For tablet: 56x56 px (white background)
                                            child: Text(
                                              '⚡',
                                              style: TextStyle(
                                                fontSize:
                                                    MediaQuery.of(
                                                              context,
                                                            ).size.width >
                                                            600
                                                        ? 24
                                                        : 20,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Charging Stations',
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 14
                                                          : 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textColor,
                                                ),
                                              ),
                                              Text(
                                                'Temukan lokasi charging',
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 10
                                                          : 9,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Kalkulator EV Card
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Navigate to calculator page
                                    Get.toNamed('/calculator');
                                  },
                                  child: Container(
                                    height:
                                        MediaQuery.of(context).size.width > 600
                                            ? 140
                                            : 120,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.secondaryColor.withOpacity(
                                            0.1,
                                          ),
                                          AppColors.primaryColor.withOpacity(
                                            0.05,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.shadowMedium
                                              .withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppColors.secondaryColor
                                            .withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            // TODO: Replace with custom image
                                            // Optimal image size: 48x48 px (white background)
                                            // For tablet: 56x56 px (white background)
                                            child: Text(
                                              '🧮',
                                              style: TextStyle(
                                                fontSize:
                                                    MediaQuery.of(
                                                              context,
                                                            ).size.width >
                                                            600
                                                        ? 24
                                                        : 20,
                                              ),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Kalkulator EV',
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 14
                                                          : 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textColor,
                                                ),
                                              ),
                                              Text(
                                                'Hitung biaya listrik',
                                                style: GoogleFonts.poppins(
                                                  fontSize:
                                                      MediaQuery.of(
                                                                context,
                                                              ).size.width >
                                                              600
                                                          ? 10
                                                          : 9,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 30,
                          ), // Spacing lebih besar untuk pemisahan

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Berita Terbaru",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.textColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/news');
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryColor.withOpacity(0.1),
                                        AppColors.secondaryColor.withOpacity(
                                          0.05,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Lihat Semua",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(
                                        Icons
                                            .arrow_forward_ios_rounded, // Ikon panah kanan
                                        color: AppColors.primaryColor,
                                        size: 16, // Sesuaikan ukuran ikon
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // Shimmer untuk "News For You"
                          Obx(() {
                            if (newsController.isLoading.value) {
                              return const ShimmerLoading();
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(), // agar tidak bentrok dengan SingleChildScrollView
                                itemCount: newsController.newNewsList.length,
                                itemBuilder: (context, index) {
                                  final e = newsController.newNewsList[index];
                                  return NewsTitle(
                                    ontap: () {
                                      FocusScope.of(context).unfocus();
                                      Get.to(NewsDetailsPage(news: e));
                                    },
                                    imageUrl: e.thumbnailUrl,
                                    tag: "EV",
                                    time: DateFormat(
                                      "dd MMM yyyy",
                                      'id_ID',
                                    ).format(e.createdAt),
                                    title: e.title,
                                    author: "InfoEV.id",
                                  );
                                },
                              );
                            }
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
