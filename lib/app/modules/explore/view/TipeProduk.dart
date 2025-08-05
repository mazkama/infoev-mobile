import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/BrandDetailController.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/styles/app_text.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infoev/core/ad_helper.dart';

class TipeProdukPage extends StatefulWidget {
  const TipeProdukPage({super.key});

  @override
  State<TipeProdukPage> createState() => _TipeProdukPageState();
}

class _TipeProdukPageState extends State<TipeProdukPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late BrandDetailController controller;

  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    controller = Get.put(BrandDetailController());

    // Get brandId from parameters
    final String brandIdStr = Get.parameters['brandId'] ?? '';
    final int brandId = int.tryParse(brandIdStr) ?? 0;

    if (brandId == 0) {
      debugPrint('Error: Invalid brand ID');
      return;
    }

    // Mengambil data merek saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchBrandDetail(brandId);
      controller.loadFilterSettings();

      // Listener untuk mengupdate search controller ketika nilai search berubah dari controller
      controller.searchQuery.listen((query) {
        if (_searchController.text != query) {
          _searchController.text = query;
        }
      });
    });

    // Inisialisasi Banner Ad
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId(isTest: false), // isTest: true untuk development
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Obx(
              () =>
                  controller.isSearching.value
                      ? _buildSearchBar()
                      : const SizedBox.shrink(),
            ),
            Obx(() {
              if (controller.isLoading.value &&
                  controller.brandDetail.value == null) {
                return Expanded(child: _buildShimmer(screenWidth));
              }

              if (controller.hasError.value) {
                return Expanded(child: _buildErrorState());
              }

              if (controller.brandDetail.value == null) {
                return const Expanded(
                  child: Center(
                    child: Text(
                      'Tidak ada data',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                );
              }

              return Expanded(child: _buildContent(context, screenWidth));
            }),
            Obx(
              () =>
                  controller.isLoading.value &&
                          controller.brandDetail.value != null
                      ? const LinearProgressIndicator(
                        backgroundColor: AppColors.backgroundColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryColor,
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      // Sementara menghilangkan bottom nav bar
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive values
    final double titleFontSize = isLargeScreen ? 22 : isTablet ? 21 : 20;
    final double countFontSize = isLargeScreen ? 15 : isTablet ? 14 : 13;
    final double padding = isLargeScreen ? 20 : isTablet ? 18 : 16;
    
    return Container(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textColor,
                      size: isTablet ? 24 : 20,
                    ),
                    onPressed: () {
                      Get.back();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Obx(
                    () => Text(
                      controller.brandDetail.value?.nameBrand ?? 'Detail Merek',
                      style: AppText.appBarTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                        fontSize: titleFontSize,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.primaryColor,
                      size: isTablet ? 24 : 20,
                    ),
                    onPressed: () {
                      controller.toggleSearch();
                      // Give focus to search field after layout update
                      if (controller.isSearching.value) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _searchFocusNode.requestFocus();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: AppColors.primaryColor,
                      size: isTablet ? 24 : 20,
                    ),
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(
            () => Visibility(
              visible:
                  controller.filterByTypeId.value > 0 ||
                  controller.sortBy.value != 'name' ||
                  controller.sortOrder.value != 'asc',
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _buildFilterInfoText(),
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        controller.resetFilters();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              'Menampilkan ${controller.filteredVehicles.length} dari ${controller.brandDetail.value?.vehicles.length ?? 0} kendaraan',
              style: AppText.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: countFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackgroundColor,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          // First apply search, then reapply current type filter
          controller.searchVehicles(value);
          if (controller.filterByTypeId.value != 0) {
            controller.filterByType(controller.filterByTypeId.value);
          }
        },
        autofocus: true,
        focusNode: _searchFocusNode,
        style: AppText.searchPageTitle.copyWith(
          color: AppColors.textColor, 
          fontSize: isTablet ? 18 : 16,
        ),
        decoration: InputDecoration(
          fillColor: AppColors.cardBackgroundColor,
          hintText: 'Cari kendaraan...',
          hintStyle: AppText.searchPageTitle.copyWith(
            color: AppColors.textTertiary, 
            fontSize: isTablet ? 18 : 16,
          ),
          prefixIcon: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppColors.textSecondary,
              size: isTablet ? 24 : 20,
            ),
            onPressed: () {
              controller.isSearching.value = false;
              _searchController.clear();
              FocusScope.of(context).unfocus();
            },
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: isTablet ? 24 : 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      controller.searchVehicles('');
                      // Reapply current type filter after clearing search
                      if (controller.filterByTypeId.value != 0) {
                        controller.filterByType(
                          controller.filterByTypeId.value,
                        );
                      }
                    },
                  )
                  : const SizedBox.shrink();
            },
          ),
          filled: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 16,
            vertical: isTablet ? 12 : 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderMedium),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: AppColors.borderMedium,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  String _buildFilterInfoText() {
    List<String> parts = [];

    if (controller.filterByTypeId.value > 0) {
      parts.add(
        'Tipe: ${controller.getTypeName(controller.filterByTypeId.value)}',
      );
    }

    if (controller.sortBy.value != 'name' ||
        controller.sortOrder.value != 'asc') {
      String sortName = controller.sortBy.value == 'name' ? 'Nama' : 'Tahun';
      String sortDirection = controller.sortOrder.value == 'asc' ? '↑' : '↓';
      parts.add('Urut: $sortName $sortDirection');
    }

    return parts.join(' • ');
  }

  Widget _buildContent(BuildContext context, double screenWidth) {
    return RefreshIndicator(
      color: AppColors.secondaryColor,
      backgroundColor: AppColors.backgroundColor,
      onRefresh: () => controller.refreshData(),
      child: CustomScrollView(
        slivers: [
          // Banner merek
          SliverToBoxAdapter(child: _buildBanner()),

          // Chip filter tipe
          SliverToBoxAdapter(child: _buildTypeFilterChips()),

          // Banner AdMob di bawah filter chips
          SliverToBoxAdapter(
            child: (_bannerAd != null)
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16), // Tambahkan margin atas & bawah
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Grid produk
          Obx(() {
            // Show loading indicator when loading and no data available yet
            if (controller.isLoading.value &&
                controller.brandDetail.value == null) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.secondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat data kendaraan...',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Show empty filter results only if:
            // 1. Not loading AND
            // 2. Brand detail exists AND
            // 3. Filtered vehicles is empty
            if (!controller.isLoading.value &&
                controller.brandDetail.value != null &&
                controller.filteredVehicles.isEmpty) {
              return SliverFillRemaining(child: _buildEmptyFilterResults());
            }

            // If no brand detail available or no vehicles after loading
            if (controller.brandDetail.value == null ||
                controller.filteredVehicles.isEmpty) {
              return const SliverFillRemaining(child: SizedBox.shrink());
            }

            // Pre-cache harga untuk semua kendaraan yang ditampilkan
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.precacheVehiclePrices(
                controller.filteredVehicles.map((v) => v.slug).toList(),
              );
            });

            return SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth >= 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final vehicle = controller.filteredVehicles[index];
                  return _buildVehicleCard(vehicle);
                }, childCount: controller.filteredVehicles.length),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final detail = controller.brandDetail.value;
    if (detail == null) return const SizedBox.shrink();

    final bannerUrl = detail.banner;
    final brandName = detail.nameBrand.toLowerCase();

    if (bannerUrl.isEmpty) return const SizedBox.shrink();

    // Get background color from MerekController
    Color backgroundColor = Get.find<MerekController>().getBrandBackgroundColor(
      brandName,
    );

    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF212121),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background color for banner
            Container(color: backgroundColor),
            // Banner image without fade animation
            CachedNetworkImage(
              imageUrl: bannerUrl,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 0),
              fadeOutDuration: const Duration(milliseconds: 0),
              placeholder: (context, url) => Container(color: backgroundColor),
              errorWidget:
                  (context, url, error) => Container(
                    color: AppColors.backgroundColor,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
                    ),
                  ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.textSecondary.withAlpha(0),
                    AppColors.textSecondary.withAlpha(179),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Brand name
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                controller.brandDetail.value?.nameBrand ?? '',
                style: AppText.displaySmall.copyWith(
                  color: AppColors.textOnPrimary,
                  shadows: [
                    Shadow(blurRadius: 10, color: AppColors.shadowMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChips() {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive values
    final double chipHeight = isLargeScreen ? 44 : isTablet ? 42 : 40;
    final double horizontalPadding = isLargeScreen ? 20 : isTablet ? 18 : 16;
    final double verticalPadding = isLargeScreen ? 10 : isTablet ? 9 : 8;
    
    return Container(
      height: chipHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Obx(() {
        if (controller.vehicleTypes.isEmpty) {
          return _buildTypeChipsShimmer();
        }

        // Get counts for each type
        Map<int, int> typeCounts = {};
        if (controller.brandDetail.value != null) {
          // Count vehicles that match both type and current search query
          final searchQuery = controller.searchQuery.value.toLowerCase();
          for (var vehicle in controller.brandDetail.value!.vehicles) {
            if (vehicle.typeId != null) {
              if (searchQuery.isEmpty ||
                  vehicle.name.toLowerCase().contains(searchQuery)) {
                typeCounts[vehicle.typeId!] =
                    (typeCounts[vehicle.typeId!] ?? 0) + 1;
              }
            }
          }
        }

        // Fixed order for vehicle types
        final fixedTypeOrder = [
          {
            'id': 0,
            'name': 'Semua',
            'count': controller.filteredVehicles.length,
          },
          {'id': 1, 'name': 'Mobil', 'count': typeCounts[1] ?? 0},
          {'id': 2, 'name': 'Sepeda Motor', 'count': typeCounts[2] ?? 0},
          {'id': 3, 'name': 'Sepeda', 'count': typeCounts[3] ?? 0},
          {'id': 5, 'name': 'Skuter', 'count': typeCounts[5] ?? 0},
        ];

        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...fixedTypeOrder
                .where((type) => type['id'] == 0 || (type['count'] as int) > 0)
                .map((type) {
                  final id = type['id'] as int;
                  final name = type['name'] as String;
                  final count = type['count'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () async {
                        await controller.filterByType(id);
                        // Reapply current search after changing type filter
                        if (controller.searchQuery.value.isNotEmpty) {
                          controller.searchVehicles(
                            controller.searchQuery.value,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ChipButtonColor(
                          isSelected: controller.filterByTypeId.value == id),
                        foregroundColor: AppColors.ChipTextColor(
                          isSelected: controller.filterByTypeId.value == id),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        id == 0 ? name : '$name ($count)',
                        style: AppText.filterChipStyle(
                            isSelected: controller.filterByTypeId.value == id,
                            color: AppColors.ChipTextColor(
                              isSelected: controller.filterByTypeId.value == id,
                            ),
                          ).copyWith(
                            fontSize: isTablet ? 8.sp : 13.sp,
                          ),
                      ),
                    ),
                  );
                })
                .toList(),
          ],
        );
      }),
    );
  }

  Widget _buildTypeChipsShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(
              width: 80,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    final typeName =
        vehicle.typeId != null ? controller.getTypeName(vehicle.typeId!) : '';
    final year = controller.getVehicleYear(vehicle);

    return _buildVehicleCardContent(vehicle, typeName, year);
  }

  Widget _buildVehicleCardContent(
    VehicleModel vehicle,
    String typeName,
    String year,
  ) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/kendaraan/${vehicle.slug}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Expanded(
                child: Stack(
                  children: [
                    // Background putih untuk semua gambar
                    Positioned.fill(child: Container(color: Colors.white)),
                    // Thumbnail image
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: vehicle.thumbnailUrl,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => Container(color: Colors.white),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppColors.backgroundColor,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.textSecondary,
                                    size: 32,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    // Type badge
                    if (typeName.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isTablet = screenWidth >= 600;
                          
                          return Positioned(
                            top: isTablet ? 6 : 8,
                            right: isTablet ? 6 : 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 6 : 8,
                                vertical: isTablet ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withAlpha(179),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeName,
                                style: AppText.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: isTablet ? 5.sp : 10.sp,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              // Info
              Container(
                color: AppColors.primaryColor, // Background hitam untuk info
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (year.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isTablet = screenWidth >= 600;
                          
                          return Text(
                            year,
                            style: AppText.vehicleCount.copyWith(
                              color: AppColors.textOnPrimary,
                              fontSize: isTablet ? 8.sp : 14.sp,
                            ),
                          );
                        },
                      ),
                    Text(
                      vehicle.name,
                      style: AppText.brandCardTitle.copyWith(
                        fontSize: 14,
                        color: AppColors.textOnPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyFilterResults() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive values
    final double iconSize = isLargeScreen ? 80 : isTablet ? 72 : 64;
    final double titleFontSize = isLargeScreen ? 18.sp : isTablet ? 16.sp : 16.sp;
    final double descriptionFontSize = isLargeScreen ? 14.sp : isTablet ? 10.sp : 10.sp;
    final double spacing1 = isLargeScreen ? 20 : isTablet ? 18 : 16;
    final double spacing2 = isLargeScreen ? 12 : isTablet ? 10 : 8;
    final double spacing3 = isLargeScreen ? 32 : isTablet ? 28 : 24;
    final double buttonPaddingH = isLargeScreen ? 32 : isTablet ? 28 : 24;
    final double buttonPaddingV = isLargeScreen ? 16 : isTablet ? 14 : 12;
    final double retryButton = isLargeScreen ? 14.sp : isTablet ? 12.sp : 12.sp;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off,
            size: iconSize,
            color: AppColors.secondaryColor,
          ),
          SizedBox(height: spacing1),
          Text(
            'Tidak ada kendaraan yang sesuai',
            textAlign: TextAlign.center,
            style: AppText.titleEmptyFilterResults.copyWith(
              color: AppColors.textTertiary,
              fontSize: titleFontSize,
            ),
          ),
          SizedBox(height: spacing2),
          Text(
            'Coba ubah kriteria pencarian atau filter Anda',
            textAlign: TextAlign.center,
            style: AppText.descriptionEmptyFilterResults.copyWith(
              color: AppColors.textTertiary,
              fontSize: descriptionFontSize,
            ),
          ),
          SizedBox(height: spacing3),
          ElevatedButton(
            onPressed: () {
              controller.resetFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: buttonPaddingH,
                vertical: buttonPaddingV,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reset Filter',
              style: AppText.buttonPrimary.copyWith(
                fontSize: retryButton,
                color: AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive values
    final double iconSize = isLargeScreen ? 80 : isTablet ? 72 : 64;
    final double titleFontSize = isLargeScreen ? 18.sp : isTablet ? 16.sp : 16.sp;
    final double descriptionFontSize = isLargeScreen ? 14.sp : isTablet ? 10.sp : 10.sp;
    final double spacing1 = isLargeScreen ? 20 : isTablet ? 18 : 16;
    final double spacing2 = isLargeScreen ? 12 : isTablet ? 10 : 8;
    final double spacing3 = isLargeScreen ? 32 : isTablet ? 28 : 24;
    final double buttonPaddingH = isLargeScreen ? 32 : isTablet ? 28 : 24;
    final double buttonPaddingV = isLargeScreen ? 16 : isTablet ? 14 : 12;
    final double retryButton = isLargeScreen ? 14.sp : isTablet ? 12.sp : 12.sp;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_wifi_off,
            size: iconSize,
            color: AppColors.secondaryColor,
          ),
          SizedBox(height: spacing1),
          Text(
            'Gagal memuat data',
            textAlign: TextAlign.center,
             style: AppText.bodyLarge.copyWith(
              color: AppColors.textTertiary,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing2),
          Text(
            // controller.errorMessage.value,
            'Pastikan koneksi internet Anda stabil',
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(
              color: AppColors.textTertiary,
              fontSize: descriptionFontSize,
            ),
          ),
          SizedBox(height: spacing3),
          ElevatedButton(
            onPressed: () => controller.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(
                horizontal: buttonPaddingH,
                vertical: buttonPaddingV,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Coba Lagi',
              style: AppText.buttonPrimary.copyWith(
                fontSize: retryButton,
                color: AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(double screenWidth) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // Banner shimmer
        SliverToBoxAdapter(
          child: Container(
            height: 180,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Shimmer.fromColors(
              baseColor: AppColors.shimmerBase,
              highlightColor: AppColors.shimmerHighlight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.shimmerBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Chip filter shimmer
        SliverToBoxAdapter(
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildTypeChipsShimmer(),
          ),
        ),

        // Grid shimmer
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth >= 600 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }, childCount: 6),
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive values for dialog
    final double titleFontSize = isLargeScreen ? 28 : isTablet ? 24 : 16;
    final double bodyFontSize = isLargeScreen ? 16 : isTablet ? 14 : 14;
    
    String sortBy = controller.sortBy.value;
    String sortOrder = controller.sortOrder.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackgroundColor,
              title: Text(
                'Filter Kendaraan',
                style: AppText.titleDialog.copyWith(
                  color: AppColors.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Urutkan Berdasarkan',
                    style: AppText.bodyDialog.copyWith(
                      color: AppColors.textColor,
                      fontSize: bodyFontSize,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSortOption(
                        'Nama',
                        sortBy == 'name',
                        () => setState(() => sortBy = 'name'),
                        isTablet,
                      ),
                      SizedBox(width: isTablet ? 12 : 16),
                      _buildSortOption(
                        'Tahun',
                        sortBy == 'year',
                        () => setState(() => sortBy = 'year'),
                        isTablet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arah Urutan',
                    style: AppText.bodyDialog.copyWith(
                      fontSize: bodyFontSize,
                      color: AppColors.textColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSortOption(
                        'Naik ↑',
                        sortOrder == 'asc',
                        () => setState(() => sortOrder = 'asc'),
                        isTablet,
                      ),
                      SizedBox(width: isTablet ? 12 : 16),
                      _buildSortOption(
                        'Turun ↓',
                        sortOrder == 'desc',
                        () => setState(() => sortOrder = 'desc'),
                        isTablet,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Reset',
                    style: AppText.bodyDialog.copyWith(
                      fontSize: bodyFontSize,
                      color: AppColors.textSecondary),
                  ),
                  onPressed: () {
                    setState(() {
                      sortBy = 'name';
                      sortOrder = 'asc';
                    });
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child: Text(
                    'Terapkan',
                    style: AppText.bodyDialog.copyWith(
                      fontSize: bodyFontSize,
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold
                      ),
                  ),
                  onPressed: () {
                    controller.sortVehicles(sortBy, sortOrder);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption(String label, bool isSelected, VoidCallback onTap, bool isTablet) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor
                  : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isTablet ? 8.sp : 14.sp,
          ),
        ),
      ),
    );
  }
}
