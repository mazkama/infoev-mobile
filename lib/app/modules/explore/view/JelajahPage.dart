import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/MerekController.dart';
import 'package:infoev/app/modules/explore/model/MerekModel.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/styles/app_text.dart';
import 'package:shimmer/shimmer.dart';

class JelajahPage extends StatefulWidget {
  const JelajahPage({super.key});

  @override
  State<JelajahPage> createState() => _JelajahPageState();
}

class _JelajahPageState extends State<JelajahPage> {
  final TextEditingController _searchController = TextEditingController();
  final MerekController controller = Get.find<MerekController>();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastSearchQuery = '';
  bool _shouldAutoFocus = true; // Flag to control autofocus behavior

  @override
  void initState() {
    super.initState();

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // TODO: Remove debug prints later
      debugPrint('DEBUG: JelajahPage - Starting data load');
      
      // Ensure type counts are loaded first
      await controller.loadTypeData();
      debugPrint('DEBUG: JelajahPage - Type data loaded');

      if (controller.merekList.isEmpty && !controller.isLoading.value) {
        debugPrint('DEBUG: JelajahPage - merekList is empty, refreshing data');
        await controller.refreshData();
      } else {
        debugPrint('DEBUG: JelajahPage - merekList has ${controller.merekList.length} items');
      }

      // Ensure focus is not active when returning from other pages
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
      }
    });

    // Add debounced listener for real-time search
    _searchController.addListener(() {
      final newQuery = _searchController.text;
      // Only trigger search if the text actually changed
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

    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure keyboard is dismissed when page becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      }
      // Reset autofocus flag after a delay to allow for normal search behavior
      if (!_shouldAutoFocus) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _shouldAutoFocus = true;
          }
        });
      }
    });
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

    // Clear search state when leaving JelajahPage
    controller.resetSearch();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_searchFocusNode.hasFocus) {
          _debounceTimer?.cancel();
          FocusScope.of(context).unfocus();
          return false;
        }
        if (controller.isSearching.value) {
          controller.resetSearch();
          controller.resetFilters(); // Reset filter saat kembali
          _searchController.clear();
          _lastSearchQuery = '';
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Obx(
                () =>
                    controller.isSearching.value
                        ? _buildSearchAppBar()
                        : Column(
                          children: [
                            _buildNormalAppBar(context),
                            _buildTypeFilterChips(),
                          ],
                        ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isSearching.value) {
                    return _buildSearchResults();
                  }
                  return _buildMainContent();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAppBar() {
    return Container(
      color: AppColors.cardBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              controller.resetSearch();
              controller.resetFilters(); // Reset filter saat tombol back diklik
              _searchController.clear();
            },
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppText.searchPageTitle.copyWith(
                color: AppColors.textColor,
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari kendaraan listrik...',
                hintStyle: AppText.searchPageTitle.copyWith(
                  color: AppColors.textTertiary,
                ),
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
                if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
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
    );
  }

  Widget _buildNormalAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;

    final double bodysmall = isLargeScreen ? 15 : isTablet ? 14 : 13;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
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
              Text(
                'Jelajah',
                style: AppText.appBarTitle.copyWith(color: AppColors.textColor),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () {
                      controller.toggleSearch();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _searchFocusNode.requestFocus();
                      });
                    },
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () {
                          _showFilterDialog(context, controller);
                        },
                      ),
                      if (controller.filterOptions['minProductCount'] != null &&
                          controller.filterOptions['minProductCount'] > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan berbagai kendaraan listrik favorit Anda',
            style: AppText.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: bodysmall,),
          ),
        ],
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
    final double leftMargin = isLargeScreen ? 20 : isTablet ? 18 : 16;
    final double rightMargin = isLargeScreen ? 10 : isTablet ? 9 : 8;
    final double bottomSpacing = isLargeScreen ? 16 : isTablet ? 14 : 12;
    
    return Column(
      children: [
        Container(
          height: chipHeight,
          // Keep background full width, no margin here!
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderMedium.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Obx(() {
            // TODO: Remove debug prints later
            debugPrint('DEBUG: JelajahPage - Building filter chips');
            debugPrint('DEBUG: JelajahPage - totalBrandsCount: ${controller.totalBrandsCount.value}');
            debugPrint('DEBUG: JelajahPage - merekList length: ${controller.merekList.length}');
            debugPrint('DEBUG: JelajahPage - brandCounts: ${controller.filterOptions['brandCounts']}');
            
            // Fixed order for vehicle types with their respective names
            final List<Map<String, dynamic>> fixedTypeOrder = [
              {'id': 0, 'name': 'Semua', 'count': controller.merekList.length},
              {'id': 1, 'name': 'Mobil', 'count': 0},
              {'id': 2, 'name': 'Sepeda Motor', 'count': 0},
              {'id': 3, 'name': 'Sepeda', 'count': 0},
              {'id': 5, 'name': 'Skuter', 'count': 0},
            ];

            // Update counts from brandCounts if available
            final brandCounts = controller.filterOptions['brandCounts'];
            if (brandCounts != null) {
              debugPrint('DEBUG: JelajahPage - Updating counts from brandCounts');
              for (var type in fixedTypeOrder) {
                if (type['id'] != 0) {
                  type['count'] = brandCounts[type['id']] ?? 0;
                }
              }
            } else {
              debugPrint('DEBUG: JelajahPage - brandCounts is null');
            }

            debugPrint('DEBUG: JelajahPage - Final type order: $fixedTypeOrder');

            return ListView(
              scrollDirection: Axis.horizontal,
              children:
                  fixedTypeOrder.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final type = entry.value;
                    final id = type['id'] as int;
                    final name = type['name'] as String;
                    final count = id == 0
                        ? () {
                            // For "Semua", show total count based on minProductCount filter
                            final minProductFilter = controller.filterOptions['minProductCount'] ?? 0;
                            if (minProductFilter > 0) {
                              return controller.merekList.where((merek) => 
                                merek.vehiclesCount >= minProductFilter).length;
                            } else {
                              return controller.merekList.length;
                            }
                          }()
                        : () {
                            // For specific types, get filtered count from controller
                            final minProductFilter = controller.filterOptions['minProductCount'] ?? 0;
                            
                            if (minProductFilter > 0) {
                              // Get filtered count for this type considering minProductCount
                              return controller.getFilteredTypeCount(id, minProductFilter);
                            } else {
                              return type['count'] as int;
                            }
                          }();
                    final isSelected =
                        id == 0
                            ? controller.filterOptions['typeId'] == null ||
                                controller.filterOptions['typeId'] == 0
                            : controller.filterOptions['typeId'] == id;

                    // Responsive padding for chips
                    final chipPadding =
                        idx == 0
                            ? EdgeInsets.only(left: leftMargin, right: rightMargin)
                            : EdgeInsets.only(right: rightMargin);

                    return Padding(
                      padding: chipPadding,
                      child: ElevatedButton(
                        onPressed: () {
                          if (id == 0) {
                            // Preserve existing filter settings and only reset typeId to null/0
                            final currentMinProductCount = controller.filterOptions['minProductCount'] ?? 0;
                            controller.filterBrands({
                              'minProductCount': currentMinProductCount,
                              'typeId': 0,
                            });
                          } else {
                            // Preserve existing filter settings and only change typeId
                            final currentMinProductCount = controller.filterOptions['minProductCount'] ?? 0;
                            controller.filterBrands({
                              'minProductCount': currentMinProductCount,
                              'typeId': id,
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ChipButtonColor(
                            isSelected: isSelected,
                          ),
                          foregroundColor: AppColors.ChipTextColor(
                            isSelected: isSelected,
                          ),
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
                          id == 0 
                            ? () {
                                final minProductFilter = controller.filterOptions['minProductCount'] ?? 0;
                                if (minProductFilter > 0) {
                                  final totalCount = controller.getTotalFilteredCount();
                                  return '$name ($totalCount)';
                                } else {
                                  return name;
                                }
                              }()
                            : '$name ($count)',
                          style: AppText.filterChipStyle(
                            isSelected: isSelected,
                            color: AppColors.ChipTextColor(
                              isSelected: isSelected,
                            ),
                          ).copyWith(
                            fontSize: isTablet ? 8.sp : 13.sp,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            );
          }),
        ),
        SizedBox(height: bottomSpacing), // Responsive spacing below the filter
      ],
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
            style: AppText.info.copyWith(color: AppColors.textTertiary),
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
                  style: AppText.sectionHeader.copyWith(
                    color: AppColors.secondaryColor,
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
            style: AppText.info.copyWith(color: AppColors.textTertiary),
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
                  style: AppText.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => controller.clearSearchHistory(),
                  child: Text(
                    'Hapus Semua',
                    style: AppText.titleMedium.copyWith(
                      color: AppColors.secondaryColor,
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
                    style: AppText.titleLarge.copyWith(
                      color: AppColors.textColor,
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
                    maxWidthDiskCache: 200,
                    maxHeightDiskCache: 200,
                    useOldImageOnUrlChange: true,
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
                    style: AppText.titleListSearchItems.copyWith(
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    '${brand.vehiclesCount} kendaraan',
                    style: AppText.descriptionListSearchItems.copyWith(
                      color: AppColors.textSecondary,
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
                  maxWidthDiskCache: 200,
                  maxHeightDiskCache: 200,
                  useOldImageOnUrlChange: true,
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
                    style: AppText.titleListSearchItems.copyWith(
                      color: AppColors.textColor,
                    ),
                  ),
                  if (vehicle['brand'] != null)
                    Text(
                      vehicle['brand']['name'] ?? '',
                      style: AppText.descriptionListSearchItems.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _buildMainContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    return RefreshIndicator(
      color: AppColors.secondaryColor,
      backgroundColor: AppColors.backgroundColor,
      onRefresh: () => controller.refreshData(),
      child: Obx(() {
        // TODO: Remove debug prints later
        debugPrint('DEBUG: JelajahPage - Building main content');
        debugPrint('DEBUG: JelajahPage - isLoading: ${controller.isLoading.value}');
        debugPrint('DEBUG: JelajahPage - merekList length: ${controller.merekList.length}');
        debugPrint('DEBUG: JelajahPage - filteredMerekList length: ${controller.filteredMerekList.length}');
        
        if (controller.isLoading.value && controller.merekList.isEmpty) {
          debugPrint('DEBUG: JelajahPage - Showing shimmer loading');
          return _buildShimmer(screenWidth);
        }

        if (!controller.isLoading.value && controller.merekList.isEmpty) {
          debugPrint('DEBUG: JelajahPage - Showing error state');
          return _buildErrorState(controller);
        }

        // Check if any filters are active
        final hasActiveFilters = (controller.filterOptions['minProductCount'] != null && 
                                 controller.filterOptions['minProductCount'] > 0) ||
                                (controller.filterOptions['typeId'] != null && 
                                 controller.filterOptions['typeId'] > 0) ||
                                controller.searchQuery.value.isNotEmpty;

        // Check if minProductCount filter is active and results in empty data
        final isMinProductCountActive = controller.filterOptions['minProductCount'] != null && 
                                       controller.filterOptions['minProductCount'] > 0;
        
        // If minProductCount is active and no brands meet the criteria, show empty state
        if (isMinProductCountActive && controller.getTotalFilteredCount() == 0) {
          debugPrint('DEBUG: JelajahPage - No brands meet minProductCount criteria, showing empty state');
          return _buildMinProductCountEmptyResults(controller);
        }

        final displayList = hasActiveFilters 
            ? controller.filteredMerekList
            : (controller.filteredMerekList.isEmpty 
                ? controller.merekList 
                : controller.filteredMerekList);

        debugPrint('DEBUG: JelajahPage - displayList length: ${displayList.length}');

        if (displayList.isEmpty) {
          // Check which type of empty state to show
          if (isMinProductCountActive) {
            return _buildMinProductCountEmptyResults(controller);
          } else {
            return _buildEmptyFilterResults(controller);
          }
        }

        debugPrint('DEBUG: JelajahPage - Building brand grid with ${displayList.length} items');
        return _buildBrandGrid(controller, screenWidth, displayList);
      }),
    );
  }

  Widget _buildBrandGrid(
    MerekController controller,
    double screenWidth,
    List<MerekModel> displayList,
  ) {
    // Responsive grid configuration similar to home_view.dart
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    final crossAxisCount = isLargeScreen 
        ? 4 // 4 columns for very large screens (desktop)
        : isTablet 
            ? 3 // 3 columns for tablets
            : 2; // 2 columns for mobile
    
    // Debug print untuk membantu troubleshooting
    debugPrint('JelajahPage Grid Debug: screenWidth=$screenWidth, isTablet=$isTablet, isLargeScreen=$isLargeScreen, crossAxisCount=$crossAxisCount');
    
    // Responsive spacing and aspect ratio
    final spacing = isTablet ? 16.0 : 12.0;
    final aspectRatio = isLargeScreen ? 1.3 : isTablet ? 1.25 : 1.2;
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification && 
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          // User has reached the end of the list
          if (controller.hasMoreData.value && !controller.isLoading.value) {
            controller.loadMoreData();
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.all(spacing),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: displayList.length + (controller.hasMoreData.value ? 1 : 0),
        itemBuilder: (context, index) {
          // TODO: Remove debug prints later
          if (index < displayList.length) {
            debugPrint('DEBUG: Building grid item $index: ${displayList[index].name}');
          }
          
          // Show loading indicator at the end
          if (index == displayList.length) {
            debugPrint('DEBUG: Showing loading indicator at end of grid');
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                ),
              ),
            );
          }
          
          final merek = displayList[index];
        return InkWell(
          onTap: () {
            debugPrint("Merek ID: ${merek.id}, Banner: ${merek.banner}");
            Get.toNamed(
              '/brand/${merek.id}',
              parameters: {'brandId': merek.id.toString()},
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
                  merek.banner != null
                      ? CachedNetworkImage(
                        imageUrl: merek.banner!,
                        maxWidthDiskCache: 200,
                        maxHeightDiskCache: 200,
                        useOldImageOnUrlChange: true,
                        imageBuilder: (context, imageProvider) {
                          return _buildCardWithContentLoaded(
                            merek,
                            imageProvider,
                          );
                        },
                        placeholder: (context, url) => _buildFullCardShimmer(),
                        errorWidget:
                            (context, url, error) =>
                                _buildFullCardShimmer(isError: true),
                      )
                      : _buildFullCardShimmer(),
            ),
          ),
        );
      },
      ),
    );
  }

  // Card dengan content sudah terload
  Widget _buildCardWithContentLoaded(
    MerekModel merek,
    ImageProvider imageProvider,
  ) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive padding and font sizes
    final cardPadding = isLargeScreen ? 16.0 : isTablet ? 14.0 : 12.0;
    final titleFontSize = isLargeScreen ? 20.0 : isTablet ? 18.0 : 16.0;
    final subtitleFontSize = isLargeScreen ? 16.0 : isTablet ? 14.0 : 12.0;
    
    return Stack(
      children: [
        // Background color
        Positioned.fill(
          child: Container(
            color: controller.getBrandBackgroundColor(merek.name),
          ),
        ),
        // Brand content with shimmer while loading
        Center(
          child: Hero(
            tag: 'brand-${merek.id}',
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) => _buildShimmerPlaceholder(),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: frame != null ? child : _buildShimmerPlaceholder(),
                  );
                },
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
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merek.name,
                  style: AppText.brandCardTitle.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: titleFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${merek.vehiclesCount} kendaraan',
                  style: AppText.vehicleCount.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: subtitleFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(color: AppColors.shimmerBase),
    );
  }

  Widget _buildFullCardShimmer({bool isError = false}) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Shimmer.fromColors(
            baseColor: AppColors.shimmerBase,
            highlightColor: AppColors.shimmerHighlight,
            child: Container(color: AppColors.shimmerBase),
          ),
          if (isError)
            Center(
              child: Icon(
                Icons.broken_image,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(0),
                    Colors.black.withAlpha(179),
                  ],
                ),
              ),
              child: Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.shimmerBase,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(double screenWidth) {
    // Use same responsive configuration as main grid
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    final crossAxisCount = isLargeScreen 
        ? 4 // 4 columns for very large screens (desktop)
        : isTablet 
            ? 3 // 3 columns for tablets
            : 2; // 2 columns for mobile
    
    final spacing = isTablet ? 16.0 : 12.0;
    final aspectRatio = isLargeScreen ? 1.3 : isTablet ? 1.25 : 1.2;
    
    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinProductCountEmptyResults(MerekController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ditemukan',
            textAlign: TextAlign.center,
            style: AppText.titleEmptyFilterResults.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan nonaktifkan atau sesuaikan\nfilter sesuai kebutuhan Anda',
            textAlign: TextAlign.center,
            style: AppText.descriptionEmptyFilterResults.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterResults(MerekController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.filter_alt_off,
            size: 64,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada merek yang sesuai',
            textAlign: TextAlign.center,
            style: AppText.titleEmptyFilterResults.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kriteria pencarian atau filter Anda',
            textAlign: TextAlign.center,
            style: AppText.descriptionEmptyFilterResults.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              controller.resetFilters();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundColor,
              foregroundColor: AppColors.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Reset Filter',
              style: AppText.buttonPrimary.copyWith(color: AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(MerekController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data merek',
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(
              color: AppColors.textColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Periksa koneksi internet Anda\ndan coba lagi',
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => controller.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundColor,
              foregroundColor: AppColors.textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Coba Lagi',
              style: AppText.buttonPrimary.copyWith(color: AppColors.textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, MerekController controller) {
    int minProductCount = controller.filterOptions['minProductCount'] ?? 0;
    String sortBy = controller.sortBy.value;
    String sortOrder = controller.sortOrder.value;
    // Default type is 0 (All)
    int selectedTypeId = controller.filterOptions['typeId'] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isTablet = screenWidth >= 600;
            
            // Responsive font sizes
            final titleFontSize = isTablet ? 18.sp : 20.sp; // Default tablet: 18.sp, Mobile: 20.sp
            final bodyFontSize = isTablet ? 12.sp : 14.sp;   // Default tablet: 12.sp, Mobile: 14.sp

            return AlertDialog(
              backgroundColor: AppColors.cardBackgroundColor,
              title: Text(
                'Filter Merek',
                style: AppText.titleDialog.copyWith(
                  color: AppColors.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              content: SizedBox(
                width: isTablet ? 400 : screenWidth * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Jumlah Kendaraan Minimal',
                      style: AppText.bodyDialog.copyWith(
                        color: AppColors.textColor,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryColor,
                        inactiveTrackColor: AppColors.primaryColor.withAlpha(
                          77,
                        ),
                        thumbColor: AppColors.primaryColor,
                        overlayColor: AppColors.primaryColor.withAlpha(25),
                        valueIndicatorColor: AppColors.primaryColor,
                        valueIndicatorTextStyle: const TextStyle(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      child: Slider(
                        value: minProductCount.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: minProductCount.toString(),
                        onChanged: (value) {
                          setState(() {
                            minProductCount = value.round();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Urutkan Berdasarkan',
                      style: AppText.bodyDialog.copyWith(
                        color: AppColors.textColor,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(
                        unselectedWidgetColor: AppColors.primaryColor.withAlpha(
                          128,
                        ),
                        radioTheme: RadioThemeData(
                          fillColor: WidgetStateProperty.all(
                            AppColors.primaryColor,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Nama',
                              style: AppText.bodyDialog.copyWith(
                                color: AppColors.textColor,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            leading: Radio<String>(
                              value: 'name',
                              groupValue: sortBy,
                              onChanged: (value) {
                                setState(() {
                                  sortBy = value!;
                                });
                              },
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Jumlah Kendaraan',
                              style: AppText.bodyDialog.copyWith(
                                color: AppColors.textColor,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            leading: Radio<String>(
                              value: 'vehicles_count',
                              groupValue: sortBy,
                              onChanged: (value) {
                                setState(() {
                                  sortBy = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Urutan',
                      style: AppText.bodyDialog.copyWith(
                        color: AppColors.textColor,
                        fontSize: bodyFontSize,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sortOrder == 'asc'
                                      ? AppColors.primaryColor
                                      : AppColors.cardBackgroundColor,
                              foregroundColor:
                                  sortOrder == 'asc'
                                      ? AppColors.cardBackgroundColor
                                      : AppColors.primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                sortOrder = 'asc';
                              });
                            },
                            child: Text(
                              'A-Z ↑',
                              style: GoogleFonts.poppins(fontSize: 14.sp),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  sortOrder == 'desc'
                                      ? AppColors.primaryColor
                                      : AppColors.cardBackgroundColor,
                              foregroundColor:
                                  sortOrder == 'desc'
                                      ? AppColors.cardBackgroundColor
                                      : AppColors.primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                sortOrder = 'desc';
                              });
                            },
                            child: Text(
                              'Z-A ↓',
                              style: GoogleFonts.poppins(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Reset',
                    style: AppText.bodyDialog.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onPressed: () {
                    // Reset semua nilai pada dialog dan reset filter sebenarnya
                    setState(() {
                      minProductCount = 0;
                      sortBy = 'name';
                      sortOrder = 'asc';
                      selectedTypeId = 0;
                    });
                    // Reset filter sebenarnya di controller
                    controller.resetFilters();
                    controller.sortBrands('name', 'asc');
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.cardBackgroundColor,
                  ),
                  child: Text(
                    'Terapkan',
                    style: AppText.bodyDialog.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    // Apply all filters together
                    controller.filterBrands({
                      'minProductCount': minProductCount,
                      'typeId': selectedTypeId,
                    });
                    controller.sortBrands(sortBy, sortOrder);
                    
                    // Close dialog
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
}
