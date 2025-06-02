import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/explore/model/MerekModel.dart';
import 'package:infoev/app/styles/app_colors.dart';

// Cache item for search history
class SearchCacheItem {
  final String query;
  final Map<String, List<dynamic>> results;
  final DateTime timestamp;

  SearchCacheItem({
    required this.query,
    required this.results,
    required this.timestamp,
  });
}

class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final MerekController controller = Get.find<MerekController>();
  final String searchQuery = Get.parameters['query'] ?? '';
  final bool isFromManualSearch = Get.parameters['fromManualSearch'] == 'true';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;
  String _currentQuery = ''; // Track current query for AppBar display

  // Advanced cache system for search history
  List<SearchCacheItem> _searchHistory = [];
  int _currentHistoryIndex = -1;

  @override
  void initState() {
    super.initState();
    // Set initial search query
    _searchController.text = searchQuery;
    _currentQuery = searchQuery; // Initialize current query

    // Perform search when page loads and cache it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchQuery.isNotEmpty) {
        _performSearchWithCache(searchQuery);
      }
    });

    // Remove debounced listener - only search on Enter press
    // _searchController.addListener() is removed

    _searchFocusNode.addListener(_onFocusChange);
  }

  // Advanced cache management
  void _performSearchWithCache(String query) async {
    try {
      // Update current query for AppBar display
      _currentQuery = query;

      // Check if we already have this query in cache
      final existingIndex = _searchHistory.indexWhere(
        (item) => item.query == query,
      );

      if (existingIndex != -1) {
        // Use cached results
        _currentHistoryIndex = existingIndex;
        controller.searchResults.value = Map<String, List<dynamic>>.from(
          _searchHistory[existingIndex].results,
        );
        controller.isSearchLoading.value = false;
      } else {
        // Perform new search
        controller.isSearchLoading.value = true;
        await controller.performSearch(query);

        // Cache the results
        if (controller.searchResults.isNotEmpty || query.isEmpty) {
          _addToSearchCache(
            query,
            Map<String, List<dynamic>>.from(controller.searchResults),
          );
        }
      }
    } catch (e) {
      // Handle search errors gracefully
      controller.isSearchLoading.value = false;
      controller.searchResults.clear();
    }
  }

  void _addToSearchCache(String query, Map<String, List<dynamic>> results) {
    // Remove existing entry if it exists
    _searchHistory.removeWhere((item) => item.query == query);

    // Add new entry
    final cacheItem = SearchCacheItem(
      query: query,
      results: results,
      timestamp: DateTime.now(),
    );

    _searchHistory.add(cacheItem);
    _currentHistoryIndex = _searchHistory.length - 1;

    // Limit cache size to prevent memory issues (keep last 20 searches)
    if (_searchHistory.length > 20) {
      _searchHistory.removeAt(0);
      _currentHistoryIndex = _searchHistory.length - 1;
    }
  }

  bool _canGoBack() {
    return _currentHistoryIndex > 0;
  }

  void _goBackInHistory() {
    if (_canGoBack()) {
      _currentHistoryIndex--;
      final previousSearch = _searchHistory[_currentHistoryIndex];

      // Update UI without triggering new search
      _searchController.text = previousSearch.query;
      _currentQuery = previousSearch.query; // Update current query for AppBar

      // Restore cached results
      controller.searchResults.value = Map<String, List<dynamic>>.from(
        previousSearch.results,
      );
      controller.isSearchLoading.value = false;
    }
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      _debounceTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();

    // Handle different navigation types
    if (isFromManualSearch) {
      // If came from manual search, ensure JelajahPage stays in search mode
      // Only clear search results but keep isSearching true
      controller.searchResults.clear();
      // Ensure search mode is maintained
      if (!controller.isSearching.value) {
        controller.isSearching.value = true;
      }
    } else {
      // If came from history selection, don't call resetSearch to keep search mode
      // Only clear search results to prevent stale data
      controller.searchResults.clear();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        if (_searchFocusNode.hasFocus) {
          _debounceTimer?.cancel();
          FocusScope.of(context).unfocus();
          return;
        }
        if (_isSearching) {
          // Check if we can go back in search history
          if (_canGoBack()) {
            _goBackInHistory();
            return;
          } else {
            // No more search history, exit to JelajahPage
            Navigator.of(context).pop();
            return;
          }
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: _isSearching ? null : _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              if (_isSearching) _buildSearchAppBar(),
              Expanded(
                child: Obx(() {
                  if (controller.isSearchLoading.value) {
                    return _buildLoadingState();
                  }

                  if (controller.searchResults.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildSearchResults();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.cardBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
        onPressed: () => Get.back(),
      ),
      title: Text(
        _currentQuery, // Use current query instead of search controller text
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.normal,
          color: AppColors.textColor,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.primaryColor),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
            // Clear search field for new search
            _searchController.clear();
            Future.delayed(const Duration(milliseconds: 100), () {
              _searchFocusNode.requestFocus();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchAppBar() {
    return Container(
      color: AppColors.cardBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
            onPressed: () {
              setState(() {
                _isSearching = false;
              });
              // Check if we can go back in search history
              if (_canGoBack()) {
                _goBackInHistory();
              } else {
                // No more search history, exit to JelajahPage
                Get.back();
              }
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
                            _performSearchWithCache('');
                          },
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ),
              onChanged: (value) {
                // No action needed, only search on Enter press
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _performSearchWithCache(value.trim());
                  setState(() {
                    _isSearching = false;
                  });
                  // Clear search field after performing search
                  _searchController.clear();
                }
              },
              autofocus: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Tidak ditemukan hasil',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci yang berbeda',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brands section (horizontal scroll)
          if (controller.searchResults.containsKey('MEREK'))
            _buildBrandsSection(),

          // Vehicles section (grid layout)
          if (controller.searchResults.containsKey('KENDARAAN'))
            _buildVehiclesSection(),
        ],
      ),
    );
  }

  Widget _buildBrandsSection() {
    final brands = controller.searchResults['MEREK'] as List<MerekModel>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Text(
                'Merek',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${brands.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Container(
                width:
                    150, // Match JelajahPage brand card width calculation (aspect ratio 1.2 with height ~125)
                margin: EdgeInsets.only(
                  right: index < brands.length - 1 ? 16 : 0,
                ), // Match JelajahPage spacing
                child: _buildBrandCard(brand),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrandCard(MerekModel brand) {
    final backgroundColor = controller.getBrandBackgroundColor(brand.name);

    return InkWell(
      onTap: () {
        Get.toNamed(
          '/brand/${brand.id}',
          parameters: {'brandId': brand.id.toString()},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium.withAlpha(51),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              brand.banner != null
                  ? _buildCardWithBanner(brand, backgroundColor)
                  : _buildCardWithoutBanner(brand, backgroundColor),
        ),
      ),
    );
  }

  Widget _buildCardWithBanner(MerekModel brand, Color backgroundColor) {
    return Stack(
      children: [
        // Background color - always visible immediately
        Positioned.fill(child: Container(color: backgroundColor)),
        // Brand banner with optimized loading
        Center(
          child: Hero(
            tag: 'brand-${brand.id}',
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: brand.banner!,
                fit: BoxFit.contain,
                // Remove placeholder to prevent background flicker
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget:
                    (context, url, error) => Icon(
                      Icons.electric_car,
                      color: AppColors.textSecondary,
                      size: 32,
                    ),
                // Optimize fade transitions
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: const Duration(milliseconds: 0),
                // Use memory cache aggressively
                memCacheWidth: 300,
                memCacheHeight: 169, // 16:9 ratio
              ),
            ),
          ),
        ),
        // Bottom gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(0),
                  Colors.black.withAlpha(179),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Brand info
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${brand.vehiclesCount} kendaraan',
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWithoutBanner(MerekModel brand, Color backgroundColor) {
    return Stack(
      children: [
        // Background color
        Positioned.fill(child: Container(color: backgroundColor)),
        // Placeholder icon
        Center(
          child: Icon(
            Icons.electric_car,
            color: AppColors.secondaryColor,
            size: 32,
          ),
        ),
        // Bottom gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(0),
                  Colors.black.withAlpha(179),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Brand info
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${brand.vehiclesCount} kendaraan',
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesSection() {
    final vehicles =
        controller.searchResults['KENDARAAN'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Text(
                'Kendaraan',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vehicles.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12), // Match TipeProduk padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7, // Match TipeProduk exactly
            crossAxisSpacing: 12, // Match TipeProduk spacing
            mainAxisSpacing: 12, // Match TipeProduk spacing
          ),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return _buildVehicleCard(vehicle);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return InkWell(
      onTap: () {
        Get.toNamed('/kendaraan/${vehicle['slug']}');
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
              // Vehicle image
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
                          imageUrl: vehicle['thumbnail_url'] ?? '',
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => Container(color: Colors.white),
                          errorWidget:
                              (context, url, error) => Container(
                                color: AppColors.backgroundColor,
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
                  ],
                ),
              ),
              // Vehicle info (dark background like TipeProduk)
              Container(
                color: AppColors.primaryColor, // Background hitam untuk info
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['name'] ?? '',
                      style: GoogleFonts.poppins(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (vehicle['brand'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        vehicle['brand']['name'] ?? '',
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
