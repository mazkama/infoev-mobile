import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/favorite_vehicles/controllers/FavoriteVehiclesController.dart';
import 'package:infoev/app/modules/favorite_vehicles/model/favoriteVehicleModel.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infoev/core/ad_helper.dart';

class FavoritVehiclesPage extends StatefulWidget {
  const FavoritVehiclesPage({super.key});

  @override
  State<FavoritVehiclesPage> createState() => _FavoritVehiclesPageState();
}

class _FavoritVehiclesPageState extends State<FavoritVehiclesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late FavoriteVehicleController controller;

  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FavoriteVehicleController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.clearAndRefreshData();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
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
          "Kendaraan Favorit",
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            color: AppColors.primaryColor,
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
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Obx(
            () =>
                controller.isSearching.value
                    ? _buildSearchBar()
                    : const SizedBox.shrink(),
          ),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.refreshFavorites();
              },
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vehicles =
                    controller.isSearching.value
                        ? controller.filteredVehicles
                        : controller.favoriteVehicles;

                if (vehicles.isEmpty) {
                  if (controller.isSearching.value &&
                      controller.searchQuery.value.isNotEmpty) {
                    return _buildEmptySearchResults();
                  }
                  return const Center(
                    child: Text("Tidak ada kendaraan favorit."),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    itemCount: vehicles.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return _buildVehicleCard(vehicle, controller);
                    },
                  ),
                );
              }),
            ),
          ),
          if (_bannerAd != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
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
          controller.searchVehicles(value);
        },
        autofocus: true,
        focusNode: _searchFocusNode,
        style: GoogleFonts.poppins(color: AppColors.textColor),
        decoration: InputDecoration(
          hintText: 'Cari kendaraan favorit...',
          hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary,
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
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      controller.searchVehicles('');
                    },
                  )
                  : const SizedBox.shrink();
            },
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
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

  Widget _buildEmptySearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
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
            'Coba ubah kriteria pencarian Anda',
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
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
    FavoriteVehicle vehicle,
    FavoriteVehicleController controller,
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
              color: AppColors.shadowMedium.withOpacity(0.2),
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
              // Thumbnail with delete icon overlay
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
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.secondaryColor,
                                    size: 32,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    // Delete icon button - di pojok kanan atas
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          controller.removeFavorite(vehicle.id);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            color: AppColors.textOnPrimary,
                            size: 20,
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
                    if (vehicle.brandName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicle.brandName,
                        style: GoogleFonts.poppins(
                          color: AppColors.textOnPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
