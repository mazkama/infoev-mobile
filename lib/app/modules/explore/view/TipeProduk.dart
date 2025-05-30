import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/BrandDetailController.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart'; 

class TipeProdukPage extends StatefulWidget {
  const TipeProdukPage({super.key});

  @override
  State<TipeProdukPage> createState() => _TipeProdukPageState();
}

class _TipeProdukPageState extends State<TipeProdukPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late BrandDetailController controller;
  
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
            Obx(() => controller.isSearching.value 
              ? _buildSearchBar()
              : const SizedBox.shrink()
            ),
            Obx(() {
              if (controller.isLoading.value && controller.brandDetail.value == null) {
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

              return Expanded(
                child: _buildContent(context, screenWidth),
              );
            }),
            Obx(() => controller.isLoading.value && controller.brandDetail.value != null
                ? const LinearProgressIndicator(
                    backgroundColor: AppColors.backgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
      // Sementara menghilangkan bottom nav bar
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
                    onPressed: () {
                      Get.back();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Obx(() => Text(
                    controller.brandDetail.value?.nameBrand ?? 'Detail Merek',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                  )),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primaryColor),
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
                    icon: const Icon(Icons.filter_list, color: AppColors.primaryColor),
                    onPressed: () {
                      _showFilterDialog(context);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Visibility(
            visible: controller.filterByTypeId.value > 0 || 
                    controller.sortBy.value != 'name' || controller.sortOrder.value != 'asc',
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildFilterInfoText(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      controller.resetFilters();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, color: AppColors.textSecondary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 8),
          Obx(() => Text(
            'Menampilkan ${controller.filteredVehicles.length} dari ${controller.brandDetail.value?.vehicles.length ?? 0} kendaraan',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
        style: GoogleFonts.poppins(color: AppColors.textColor),
        decoration: InputDecoration(
          hintText: 'Cari kendaraan...',
          hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
          prefixIcon: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
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
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _searchController.clear();
                      controller.searchVehicles('');
                      // Reapply current type filter after clearing search
                      if (controller.filterByTypeId.value != 0) {
                        controller.filterByType(controller.filterByTypeId.value);
                      }
                    },
                  )
                : const SizedBox.shrink();
            },
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            borderSide: const BorderSide(color: AppColors.borderMedium, width: 1),
          ),
        ),
      ),
    );
  }

  String _buildFilterInfoText() {
    List<String> parts = [];
    
    if (controller.filterByTypeId.value > 0) {
      parts.add('Tipe: ${controller.getTypeName(controller.filterByTypeId.value)}');
    }
    
    if (controller.sortBy.value != 'name' || controller.sortOrder.value != 'asc') {
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
          SliverToBoxAdapter(
            child: _buildBanner(),
          ),
          
          // Chip filter tipe
          SliverToBoxAdapter(
            child: _buildTypeFilterChips(),
          ),
          
          // Grid produk
          Obx(() {
            if (controller.filteredVehicles.isEmpty) {
              return SliverFillRemaining(
                child: _buildEmptyFilterResults(),
              );
            }
            
            // Pre-cache harga untuk semua kendaraan yang ditampilkan
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.precacheVehiclePrices(
                controller.filteredVehicles.map((v) => v.slug).toList()
              );
            });
            
            return SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final vehicle = controller.filteredVehicles[index];
                    return _buildVehicleCard(vehicle);
                  },
                  childCount: controller.filteredVehicles.length,
                ),
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
    Color backgroundColor = Get.find<MerekController>().getBrandBackgroundColor(brandName);
    
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
            Container(
              color: backgroundColor,
            ),
            // Banner image without fade animation
            CachedNetworkImage(
              imageUrl: bannerUrl,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 0),
              fadeOutDuration: const Duration(milliseconds: 0),
              placeholder: (context, url) => Container(
                color: backgroundColor,
              ),
              errorWidget: (context, url, error) => Container(
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
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AppColors.shadowMedium,
                    ),
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
    return Container(
      height: 40,
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
                typeCounts[vehicle.typeId!] = (typeCounts[vehicle.typeId!] ?? 0) + 1;
              }
            }
          }
        }
        
        // Fixed order for vehicle types
        final fixedTypeOrder = [
          {'id': 0, 'name': 'Semua', 'count': controller.filteredVehicles.length},
          {'id': 1, 'name': 'Mobil', 'count': typeCounts[1] ?? 0},
          {'id': 2, 'name': 'Sepeda Motor', 'count': typeCounts[2] ?? 0},
          {'id': 3, 'name': 'Sepeda', 'count': typeCounts[3] ?? 0},
          {'id': 5, 'name': 'Skuter', 'count': typeCounts[5] ?? 0},
        ];
        
        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...fixedTypeOrder.where((type) => type['id'] == 0 || (type['count'] as int) > 0).map((type) {
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
                      controller.searchVehicles(controller.searchQuery.value);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.filterByTypeId.value == id
                        ? AppColors.secondaryColor.withAlpha(45)
                        : AppColors.backgroundSecondary,
                    foregroundColor: controller.filterByTypeId.value == id
                        ? AppColors.secondaryColor
                        : AppColors.textColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    id == 0 ? name : '$name ($count)',
                    style: GoogleFonts.poppins(
                      fontWeight: controller.filterByTypeId.value == id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
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
    final typeName = vehicle.typeId != null ? controller.getTypeName(vehicle.typeId!) : '';
    final year = vehicle.spec?.value.split('.').first ?? '';
    
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
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    // Thumbnail image
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: vehicle.thumbnailUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.white,
                          ),
                          errorWidget: (context, url, error) => Container(
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
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
                    Text(
                      vehicle.name,
                      style: GoogleFonts.poppins(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (year.isNotEmpty)
                      Text(
                        'Tahun $year',
                        style: GoogleFonts.poppins(
                          color: AppColors.textOnPrimary,
                          fontSize: 12,
                        ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.filter_alt_off,
            size: 64,
            color: AppColors.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada kendaraan yang sesuai',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kriteria pencarian atau filter Anda',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              controller.resetFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reset Filter',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.signal_wifi_off,
            size: 64,
            color: AppColors.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => controller.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
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
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
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
              crossAxisCount: screenWidth > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
              },
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showFilterDialog(BuildContext context) {
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
                style: GoogleFonts.poppins(
                  color: AppColors.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Urutkan Berdasarkan',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSortOption(
                        'Nama', 
                        sortBy == 'name', 
                        () => setState(() => sortBy = 'name'),
                      ),
                      const SizedBox(width: 16),
                      _buildSortOption(
                        'Tahun',
                        sortBy == 'year',
                        () => setState(() => sortBy = 'year'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arah Urutan',
                    style: GoogleFonts.poppins(
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSortOption(
                        'Naik ↑', 
                        sortOrder == 'asc', 
                        () => setState(() => sortOrder = 'asc'),
                      ),
                      const SizedBox(width: 16),
                      _buildSortOption(
                        'Turun ↓',
                        sortOrder == 'desc',
                        () => setState(() => sortOrder = 'desc'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Reset',
                    style: GoogleFonts.poppins(color: AppColors.textSecondary),
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
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    controller.sortVehicles(sortBy, sortOrder);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  Widget _buildSortOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}