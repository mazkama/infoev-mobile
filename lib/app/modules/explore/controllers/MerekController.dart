import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:infoev/app/modules/explore/model/MerekModel.dart';
import 'package:infoev/app/services/AppException.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:infoev/app/services/app_token_service.dart'; // Import AppTokenService

class MerekController extends GetxController {
  var merekList = <MerekModel>[].obs;
  var filteredMerekList = <MerekModel>[].obs;
  var isLoading = false.obs;
  var hasMoreData = true.obs;
  var isRefreshing = false.obs;
  var currentPage = 1;
  final int pageSize = 10;
  final Duration cacheValidity = const Duration(hours: 12); // Extend cache to 12 hours
  var totalBrandsCount = 0.obs; // Total count from API pagination

  // AppTokenService untuk x-app-key
  late final AppTokenService _appTokenService;
  
  // Search and filter state
  var isSearching = false.obs;
  var searchQuery = ''.obs;
  var sortBy = 'name'.obs;
  var sortOrder = 'asc'.obs;
  var filterOptions = <String, dynamic>{}.obs;

  // Cache storage untuk setiap tipe filter
  final Map<String, List<MerekModel>> _filterCache = {};
  final Map<String, bool> _filterCacheComplete = {}; // Track apakah cache sudah complete (semua page loaded)
  final Map<String, int> _filterCacheLastPage = {}; // Track page terakhir yang di-cache
  final Map<String, bool> _filterHasMoreData = {}; // Track apakah masih ada data lagi
  final Set<String> _backgroundFetchInProgress = {}; // Track background fetch yang sedang berjalan

  // Mapping untuk ukuran gambar berdasarkan merek
  final Map<String, double> brandImageScales = {
    'alva': 0.7,
    'bf goodrich': 0.6,
    'bmw': 0.85,
    'benelli': 0.6,
    'byd': 0.6,
    'cfmoto': 0.6,
    'charged': 0.6,
    'chery': 0.8,
    'citroen': 0.8,
    'davigo': 0.7,
    'greentech': 0.7,
    'honda': 0.7,
    'hyundai': 0.85,
    'imoto': 0.7,
    'indomobil': 0.6,
    'jac': 0.7,
    'jaguar': 0.7,
    'kia': 0.7,
    'kool': 0.7,
    'kawasaki': 0.5,
    'niu': 0.5,
    'mercedez benz': 0.8,
    'ofero': 0.7,
    'pacific': 0.7,
    'rakata': 0.7,
    'savart': 0.8,
    'tesla': 0.9,
    'toyota': 0.95,
    'tvs': 0.6,
    'united': 0.6,
    'vespa': 0.8,
    'viar': 0.8,
    'wmoto': 0.7,
    'xiaomi': 0.8,
    'yadea': 0.7,
  };

  // Mapping untuk warna background berdasarkan merek
  // * Catatan: Merek dengan logo/banner transparan PNG mungkin perlu background tertentu
  // * Contoh:
  // * - Logo putih butuh background gelap (hitam/biru/merah)
  // * - Logo hitam butuh background terang (putih/abu-abu muda)
  // * Default: Putih (0xFFFFFFFF)
  final Map<String, int> brandBackgroundColors = {
    // Contoh merek dengan logo putih (butuh background gelap)
    'alva': 0xFF000000, // Hitam
    'byd': 0xFF000000, // Hitam
    'davigo': 0xFF000000, // Hitam
    'niu': 0xFF000000, // Hitam
    // Contoh merek dengan logo hitam (butuh background terang)
    'benelli': 0xFFFFFFFF, // Putih
    // Tambahkan kustomisasi warna background sesuai kebutuhan
  };

  // Map untuk nama tipe kendaraan
  final Map<int, String> vehicleTypeNames = {
    1: 'Mobil',
    2: 'Sepeda Motor',
    3: 'Sepeda',
    5: 'Skuter',
  };

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService(); // Initialize AppTokenService
    _initializeData();
  }
  
  // Hapus/matikan _getAuthHeaders(), tidak perlu lagi

  Future<void> _initializeData() async {
    try {
      // TODO: Remove debug prints later
      debugPrint('DEBUG: Starting _initializeData');
      
      // Load cached type counts first
      await _loadTypeCountsFromCache();

      // Load brands and other data
      await Future.wait([
        _loadCachedDataFirst(),
        _loadFilterSettings(),
        _loadBrandBackgroundColors(),
        _loadSearchHistory(),
      ]);

      // If no cached type counts, fetch them
      if ((filterOptions['brandCounts'] as Map<dynamic, dynamic>?)?.isEmpty ??
          true) {
        debugPrint('DEBUG: No cached type counts, fetching from API');
        await _fetchTypeCountsFromApi();
      } else {
        debugPrint('DEBUG: Type counts loaded from cache: ${filterOptions['brandCounts']}');
      }

      // Ensure filtered count cache is populated after initialization
      ensureFilteredCountCache();
    } catch (e) {
      debugPrint('ERROR: Error initializing data: $e');
    }
  }

  // Tambahkan fungsi cast<T> jika belum ada di file ini
  T cast<T>(dynamic value, String fieldName) {
    if (value == null) return null as T;
    
    // Handle int conversion
    if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString()))) {
      if (value is int) return value as T;
      if (value is String) {
        final intValue = int.tryParse(value);
        if (intValue != null) return intValue as T;
      }
      // Jika gagal convert ke int dan tipe membolehkan null, return null
      if (T.toString().contains('?')) return null as T;
      // Jika tidak, gunakan nilai default untuk mencegah error
      debugPrint('Warning: Failed to cast "$value" to int for field "$fieldName"');
      return 0 as T; // Return default value daripada mencoba cast
    }
    
    // Handle String dan tipe lainnya seperti sebelumnya
    if ((T == String || RegExp(r'^String(\?|)$').hasMatch(T.toString()))) {
      return value.toString() as T;
    }
    
    if (value is T) return value;
    
    // Tambahkan try-catch untuk mencegah crash
    try {
      return value as T;
    } catch (e) {
      debugPrint('Cast error for field "$fieldName": $e');
      if (T == int) return 0 as T;
      if (T == String) return '' as T;
      if (T == bool) return false as T;
      throw Exception('Cannot cast ${value.runtimeType} to $T for field "$fieldName"');
    }
  }

  Future<void> _loadTypeCountsFromCache() async {
    try {
      // TODO: Remove debug prints later
      debugPrint('DEBUG: Loading type counts from cache');
      
      final prefs = await SharedPreferences.getInstance();
      final countsStr = prefs.getString('type_counts');
      final timestamp = prefs.getInt('type_counts_timestamp');

      debugPrint('DEBUG: Cache countsStr: $countsStr');
      debugPrint('DEBUG: Cache timestamp: $timestamp');

      if (countsStr != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        debugPrint('DEBUG: Cache age: ${cacheAge}ms, validity: ${cacheValidity.inMilliseconds}ms');
        
        if (cacheAge < cacheValidity.inMilliseconds) {
          // Perbaikan: parsing Map<String, dynamic> lalu konversi ke Map<int, int>
          final rawMap = Map<String, dynamic>.from(jsonDecode(countsStr));
          final counts = <int, int>{};
          rawMap.forEach((key, value) {
            counts[cast<int>(key, 'brand_id')] = cast<int>(value, 'count');
          });
          filterOptions['brandCounts'] = counts;
          debugPrint('DEBUG: Loaded type counts from cache: $counts');
          update();
          return;
        } else {
          debugPrint('DEBUG: Cache expired');
        }
      } else {
        debugPrint('DEBUG: No cache found');
      }
    } catch (e) {
      debugPrint('Error loading type counts from cache: $e');
    }
  }

  Future<void> _fetchTypeCountsFromApi() async {
    try {
      // TODO: Remove debug prints later
      debugPrint('DEBUG: Starting _fetchTypeCountsFromApi');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Fetch type counts from new /tipe endpoint
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse('$prodUrl/tipe'),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      debugPrint('DEBUG: /tipe API URL: $prodUrl/tipe');
      debugPrint('DEBUG: /tipe API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('DEBUG: /tipe API response data: $data');
        
        final List<dynamic> items = data['items'] ?? [];
        debugPrint('DEBUG: Items from /tipe API: $items');
        
        Map<int, int> counts = {};
        
        // Map the response to type IDs
        for (var item in items) {
          final String slug = item['slug'] ?? '';
          final int brandsCount = item['brands_count'] ?? 0;
          
          debugPrint('DEBUG: Processing slug: $slug, count: $brandsCount');
          
          // Map slug to type ID
          int? typeId;
          switch (slug) {
            case 'mobil':
              typeId = 1;
              break;
            case 'sepeda-motor':
              typeId = 2;
              break;
            case 'sepeda':
              typeId = 3;
              break;
            case 'skuter':
              typeId = 5;
              break;
          }
          
          if (typeId != null) {
            counts[typeId] = brandsCount;
            debugPrint('DEBUG: Mapped typeId $typeId to count $brandsCount');
          }
        }
        
        // Set default count for Skuter if not found
        if (!counts.containsKey(5)) {
          counts[5] = 0;
          debugPrint('DEBUG: Set default count 0 for Skuter (typeId 5)');
        }

        debugPrint('DEBUG: Final type counts: $counts');

        if (counts.isNotEmpty) {
          filterOptions['brandCounts'] = counts;
          // Convert keys to String for JSON encoding
          final countsStringKey = counts.map((k, v) => MapEntry(k.toString(), v));
          await prefs.setString('type_counts', jsonEncode(countsStringKey));
          await prefs.setInt(
            'type_counts_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );
          debugPrint('DEBUG: Type counts saved to cache and filterOptions updated');
          update();
        }
      } else {
        debugPrint('ERROR: /tipe API failed with status ${response.statusCode}');
        debugPrint('ERROR: Response body: ${response.body}');
      }
    } catch (e) {
      debugPrint('ERROR: Error fetching type counts: $e');
    }
  }

  Future<void> _loadFilterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString('filter_settings');

      if (filterJson != null) {
        final Map<String, dynamic> settings = jsonDecode(filterJson);
        if (settings.containsKey('searchQuery')) {
          searchQuery.value = settings['searchQuery'] as String;
        }
        if (settings.containsKey('sortBy')) {
          sortBy.value = settings['sortBy'] as String;
        }
        if (settings.containsKey('sortOrder')) {
          sortOrder.value = settings['sortOrder'] as String;
        }
        if (settings.containsKey('filterOptions')) {
          filterOptions.value = Map<String, dynamic>.from(
            settings['filterOptions'],
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading filter settings: $e');
    }
  }

  Future<void> _saveFilterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> settings = {
        'searchQuery': searchQuery.value,
        'sortBy': sortBy.value,
        'sortOrder': sortOrder.value,
        'filterOptions': filterOptions,
      };

      await prefs.setString('filter_settings', jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving filter settings: $e');
    }
  }

  // Dapatkan ukuran gambar untuk merek tertentu
  double getImageScale(String brandName) {
    final String lowerName = brandName.toLowerCase();
    return brandImageScales[lowerName] ?? 1.0;
  }

  // Set ukuran gambar untuk merek tertentu
  void setImageScale(String brandName, double scale) {
    brandImageScales[brandName.toLowerCase()] = scale;
    _saveBrandImageScales();
  }

  Future<void> _saveBrandImageScales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('brand_image_scales', jsonEncode(brandImageScales));
    } catch (e) {
      debugPrint('Error saving brand image scales: $e');
    }
  }

  Future<void> _loadBrandImageScales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scales = prefs.getString('brand_image_scales');

      if (scales != null) {
        final Map<String, dynamic> savedScales = jsonDecode(scales);
        savedScales.forEach((key, value) {
          brandImageScales[key] = value.toDouble();
        });
      }
    } catch (e) {
      debugPrint('Error loading brand image scales: $e');
    }
  }

  // Dapatkan warna background untuk merek tertentu
  Color getBrandBackgroundColor(String brandName) {
    final String lowerName = brandName.toLowerCase();
    // Ambil warna dari mapping atau gunakan putih sebagai default
    final int colorValue = brandBackgroundColors[lowerName] ?? 0xFFFFFFFF;
    return Color(colorValue);
  }

  // Set warna background untuk merek tertentu
  void setBrandBackgroundColor(String brandName, Color color) {
    brandBackgroundColors[brandName.toLowerCase()] = color.value;
    _saveBrandBackgroundColors();
  }

  Future<void> _saveBrandBackgroundColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'brand_background_colors',
        jsonEncode(brandBackgroundColors),
      );
    } catch (e) {
      debugPrint('Error saving brand background colors: $e');
    }
  }

  Future<void> _loadBrandBackgroundColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colors = prefs.getString('brand_background_colors');

      if (colors != null) {
        final Map<String, dynamic> savedColors = jsonDecode(colors);
        savedColors.forEach((key, value) {
          brandBackgroundColors[key] = value;
        });
      }
    } catch (e) {
      debugPrint('Error loading brand background colors: $e');
    }
  }

  Future<void> _loadCachedDataFirst() async {
    isLoading.value = true;

    try {
      bool dataLoaded = false;
      List<MerekModel>? loadedData;

      // Coba load dari file JSON dulu
      final file = await _getLocalFile('merek_data.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);

        // Verifikasi waktu cache
        final int? timestamp = data['timestamp'];
        if (timestamp != null) {
          final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(
            timestamp,
          );
          if (DateTime.now().difference(cacheTime) < cacheValidity) {
            final List<dynamic> items = data['items'];
            loadedData = items.map((item) => MerekModel.fromJson(item)).toList();
            dataLoaded = true;
            debugPrint('DEBUG: Loaded ${loadedData.length} items from local file cache');
          }
        }
      }

      // Jika tidak ada data dari file, coba dari SharedPreferences
      if (!dataLoaded) {
        final prefs = await SharedPreferences.getInstance();
        final cacheTime = prefs.getInt('merek_cache_time');
        final cacheData = prefs.getString('merek_data');

        if (cacheTime != null && cacheData != null) {
          final DateTime cacheDateTime = DateTime.fromMillisecondsSinceEpoch(
            cacheTime,
          );
          if (DateTime.now().difference(cacheDateTime) < cacheValidity) {
            final List<dynamic> data = jsonDecode(cacheData);
            loadedData = data.map((item) => MerekModel.fromJson(item)).toList();
            dataLoaded = true;
            debugPrint('DEBUG: Loaded ${loadedData.length} items from SharedPreferences cache');
          }
        }
      }

      // Jika berhasil load dari cache
      if (dataLoaded && loadedData != null && loadedData.isNotEmpty) {
        // Set data ke merekList
        merekList.value = List<MerekModel>.from(loadedData);
        
        // PENTING: Populate memory cache dengan status complete
        final parentCacheKey = _getCacheKey(0, 0); // For "Semua" without filters
        _filterCache[parentCacheKey] = List<MerekModel>.from(loadedData);
        _filterCacheComplete[parentCacheKey] = true; // Mark as complete
        _filterHasMoreData[parentCacheKey] = false; // No more data to fetch
        _filterCacheLastPage[parentCacheKey] = 1; // Mark as loaded from first page
        
        // Set pagination state untuk prevent infinite scroll
        hasMoreData.value = false;
        currentPage = 1;
        
        debugPrint('DEBUG: Cache loaded and marked as complete. hasMoreData: ${hasMoreData.value}');
        
        // Sync to child caches
        _syncParentToChildCache(parentCacheKey, loadedData, 0);
        
        _applyFilters();
        await _loadBrandImageScales();
        
        // Optional: Background refresh tanpa blocking UI jika cache sudah lama
        final lastCacheTime = await _getLastCacheTime();
        if (lastCacheTime != null && 
            DateTime.now().difference(lastCacheTime).inHours > 6) {
          debugPrint('DEBUG: Cache older than 6 hours, refreshing in background');
          Future.delayed(const Duration(seconds: 2), () {
            fetchMerek(isRefresh: true);
          });
        }
      } else {
        // Jika tidak ada data cached yang valid, load dari API
        debugPrint('DEBUG: No valid cache found, loading from API');
        await fetchMerek(isRefresh: true);
      }
    } catch (e) {
      debugPrint('ERROR: Error loading initial data: $e');
      await fetchMerek(isRefresh: true);
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Get last cache time untuk background refresh decision
  Future<DateTime?> _getLastCacheTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('merek_cache_time');
      if (cacheTime != null) {
        return DateTime.fromMillisecondsSinceEpoch(cacheTime);
      }
      
      // Check file cache
      final file = await _getLocalFile('merek_data.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        final int? timestamp = data['timestamp'];
        if (timestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
    } catch (e) {
      debugPrint('ERROR: Failed to get last cache time: $e');
    }
    return null;
  }

  Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    isRefreshing.value = true;
    currentPage = 1;
    merekList.clear();
    filteredMerekList.clear();
    
    // Clear only current filter cache, not all filters
    final int? activeTypeId = filterOptions['typeId'];
    final minProductCount = filterOptions['minProductCount'] ?? 0;
    final activeCacheKey = _getCacheKey(activeTypeId ?? 0, minProductCount);
    clearFilterCacheForKey(activeCacheKey);
    
    // PERBAIKAN: Panggil endpoint yang sesuai berdasarkan filter yang aktif
    try {
      if (activeTypeId != null && activeTypeId > 0) {
        // Jika ada type filter aktif, gunakan endpoint dengan vehicle_type
        final typeSlug = getTypeSlug(activeTypeId);
        if (typeSlug != null) {
          debugPrint('DEBUG: Refreshing data for type: $typeSlug');
          await fetchMerekByType(typeSlug, isRefresh: true);
        } else {
          debugPrint('ERROR: Unknown typeSlug for typeId: $activeTypeId');
          await fetchMerek(isRefresh: true);
        }
      } else {
        // Untuk "Semua", gunakan endpoint default
        debugPrint('DEBUG: Refreshing data for all types');
        await fetchMerek(isRefresh: true);
      }
    } catch (e) {
      debugPrint('ERROR: Error in refreshData: $e');
      // Fallback ke fetchMerek jika ada error
      await fetchMerek(isRefresh: true);
    }
    
    isRefreshing.value = false;
  }

  Future<void> fetchMerek({bool isRefresh = false}) async {
    if (isLoading.value && !isRefresh) return;

    debugPrint('DEBUG: Starting fetchMerek, isRefresh: $isRefresh, currentPage: $currentPage');

    isLoading.value = true;

    try {
      // Determine page to fetch
      int pageToFetch = isRefresh ? 1 : currentPage;
      final minProductCount = filterOptions['minProductCount'] ?? 0;
      
      // Build URL with optional minProductCount filter for "Semua"
      String url = '$prodUrl/merek?page=$pageToFetch&per_page=$pageSize';
      if (minProductCount > 0) {
        url += '&min_vehicles_count=$minProductCount';
      }
      
      debugPrint('DEBUG: Fetching all brands URL: $url');
      
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      debugPrint('DEBUG: /merek API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('DEBUG: /merek API response keys: ${data.keys.toList()}');
        
        final List<dynamic> items = data['items'] ?? [];
        debugPrint('DEBUG: Received ${items.length} items from API');
        
        // Handle pagination info
        final bool hasMorePages = data['has_more_pages'] ?? false;
        final int total = data['total'] ?? 0;
        hasMoreData.value = hasMorePages;
        totalBrandsCount.value = total;
        
        debugPrint('DEBUG: hasMorePages: $hasMorePages, total: $total');

        // Process items directly from new API structure
        final processedItems = await _processMerekItems(items);
        debugPrint('DEBUG: Processed ${processedItems.length} items');

        // Check cache untuk menentukan apakah perlu replace atau hanya update
        final minProductCount = filterOptions['minProductCount'] ?? 0;
        final cacheKey = _getCacheKey(0, minProductCount); // typeId = 0 untuk "Semua"
        
        if (isRefresh) {
          // PERBAIKAN: Untuk refresh, selalu replace data lama dengan data baru
          merekList.value = processedItems;
          currentPage = 2; // Next page for infinite scroll
          debugPrint('DEBUG: Refreshed data, merekList now has ${merekList.length} items');
          
          // Replace cache dengan data baru (tanpa duplikasi)
          _filterCache[cacheKey] = List<MerekModel>.from(merekList);
        } else if (!isRefresh) {
          // Pagination - append data tanpa duplikasi
          final existingIds = merekList.map((e) => e.id).toSet();
          final newItems = processedItems.where((item) => !existingIds.contains(item.id)).toList();
          
          if (newItems.isNotEmpty) {
            merekList.addAll(newItems);
            currentPage++;
            debugPrint('DEBUG: Added ${newItems.length} new items, merekList now has ${merekList.length} items');
            
            if (!_filterCache.containsKey(cacheKey)) {
              _filterCache[cacheKey] = [];
            }
            
            // Prevent duplicates in cache too
            final existingCacheIds = _filterCache[cacheKey]!.map((e) => e.id).toSet();
            final newCacheItems = newItems.where((item) => !existingCacheIds.contains(item.id)).toList();
            _filterCache[cacheKey]!.addAll(newCacheItems);
          } else {
            debugPrint('DEBUG: No new items to add, all items already exist');
          }
        }
        
        _filterCacheLastPage[cacheKey] = currentPage - 1;
        _filterHasMoreData[cacheKey] = hasMorePages;
        _filterCacheComplete[cacheKey] = !hasMorePages; // Mark complete jika tidak ada lagi data
        
        debugPrint('DEBUG: Updated cache for $cacheKey, total items: ${_filterCache[cacheKey]!.length}');

        // BIDIRECTIONAL CACHE: Sinkronisasi parent cache ke child caches
        _syncParentToChildCache(cacheKey, _filterCache[cacheKey]!, minProductCount);

        // PERBAIKAN 3: Jika cache 'Semua' complete, populate cache untuk type lainnya
        if (!hasMorePages && cacheKey.startsWith('all')) {
          debugPrint('DEBUG: Semua cache is complete, populating type-specific caches');
          _populateTypeSpecificCaches(minProductCount);
        }
        
        // PERBAIKAN 4: Sinkronisasi data baru dengan cache type-specific yang sudah ada
        if (isRefresh || !isRefresh) {
          _syncNewDataWithTypeSpecificCaches(processedItems, minProductCount);
        }

        _applyFilters();
        debugPrint('DEBUG: Applied filters, filteredMerekList has ${filteredMerekList.length} items');

        if (isRefresh) {
          // Save data to cache with filter key
          _updateCacheWithFilter(items, minProductCount);
        }
      } else {
        debugPrint('ERROR: API Error: ${response.statusCode}');
        debugPrint('ERROR: Response: ${response.body}');
        ErrorHandlerService.handleError(
          AppException(
            message: 'Gagal memuat data merek. Silakan coba lagi nanti.',
            type: ErrorType.server,
            statusCode: response.statusCode,
          ),
          showToUser: true,
        );
      }
    } catch (e) {
      debugPrint('ERROR: Error fetching data: $e');
      ErrorHandlerService.handleError(e, showToUser: true);
    } finally {
      isLoading.value = false;
    }
  }

  // Method for infinite scroll loading
  Future<void> loadMoreData() async {
    if (isLoading.value) return;
    
    final int? activeTypeId = filterOptions['typeId'];
    final minProductCount = filterOptions['minProductCount'] ?? 0;
    final cacheKey = _getCacheKey(activeTypeId ?? 0, minProductCount);
    
    debugPrint('DEBUG: loadMoreData called for cacheKey: $cacheKey');
    debugPrint('DEBUG: Cache complete: ${_filterCacheComplete[cacheKey] ?? false}');
    debugPrint('DEBUG: Has more data from cache: ${_filterHasMoreData[cacheKey] ?? true}');
    debugPrint('DEBUG: Current hasMoreData.value: ${hasMoreData.value}');
    
    // Cek apakah cache sudah complete (semua page sudah di-load)
    if (_filterCacheComplete[cacheKey] ?? false) {
      debugPrint('DEBUG: Cache is complete for $cacheKey, no more data to load');
      hasMoreData.value = false;
      return;
    }
    
    // Cek dari cache apakah memang masih ada data yang bisa di-load
    if (!(_filterHasMoreData[cacheKey] ?? true)) {
      debugPrint('DEBUG: No more data available for $cacheKey according to cache');
      hasMoreData.value = false;
      return;
    }
    
    // Final check sebelum fetch
    if (!hasMoreData.value) {
      debugPrint('DEBUG: hasMoreData is false, stopping loadMoreData');
      return;
    }
    
    // Set current page berdasarkan cache yang sudah ada
    if (_filterCacheLastPage.containsKey(cacheKey)) {
      currentPage = (_filterCacheLastPage[cacheKey] ?? 0) + 1;
      debugPrint('DEBUG: Set currentPage from cache: $currentPage for $cacheKey');
    }
    
    // Check if we're currently filtering by type
    if (activeTypeId != null && activeTypeId > 0) {
      final typeSlug = getTypeSlug(activeTypeId);
      if (typeSlug != null) {
        debugPrint('DEBUG: Loading more data for type: $typeSlug');
        await fetchMerekByType(typeSlug, isRefresh: false);
        return;
      }
    }
    
    // Default behavior for "Semua" or no type filter
    debugPrint('DEBUG: Loading more data for all brands');
    await fetchMerek(isRefresh: false);
  }

  Future<List<MerekModel>> _processMerekItems(List<dynamic> items) async {
    try {
      // TODO: Remove debug prints later
      debugPrint('DEBUG: Processing ${items.length} items');
      
      final List<MerekModel> result = [];

      for (var item in items) {
        // Create MerekModel directly from new API structure
        // The thumbnail_url is now included in the response
        debugPrint('DEBUG: Processing item: $item');
        MerekModel merek = MerekModel.fromJson(item);
        debugPrint('DEBUG: Created MerekModel: id=${merek.id}, name=${merek.name}, banner=${merek.banner}');
        result.add(merek);
      }

      debugPrint('DEBUG: Processed ${result.length} MerekModel items');
      return result;
    } catch (e) {
      debugPrint('ERROR: Error in _processMerekItems: $e');
      ErrorHandlerService.handleError(
        e,
        showToUser: true,
      );
      return [];
    }
  }

  Future<void> _updateCacheWithFilter(List<dynamic> items, int minProductCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = minProductCount > 0 ? 'merek_data_min_$minProductCount' : 'merek_data';
      final timeKey = minProductCount > 0 ? 'merek_cache_time_min_$minProductCount' : 'merek_cache_time';
      
      await prefs.setString(cacheKey, jsonEncode(items));
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('DEBUG: Cached data with key: $cacheKey');
    } catch (e) {
      debugPrint('Error updating cache with filter: $e');
    }
  }

  Future<void> _updateCacheWithTypeFilter(List<dynamic> items, String typeSlug, int minProductCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String cacheKey, timeKey;
      
      if (minProductCount > 0) {
        cacheKey = 'merek_data_type_${typeSlug}_min_$minProductCount';
        timeKey = 'merek_cache_time_type_${typeSlug}_min_$minProductCount';
      } else {
        cacheKey = 'merek_data_type_$typeSlug';
        timeKey = 'merek_cache_time_type_$typeSlug';
      }
      
      await prefs.setString(cacheKey, jsonEncode(items));
      await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('DEBUG: Cached type data with key: $cacheKey');
    } catch (e) {
      debugPrint('Error updating cache with type filter: $e');
    }
  }

  // Fungsi untuk mencari merek
  void searchBrands(String query) {
    searchQuery.value = query;
    _applyFilters();
    _saveFilterSettings();
  }

  // Fungsi untuk mengurutkan merek
  void sortBrands(String by, String order) {
    sortBy.value = by;
    sortOrder.value = order;
    _applyFilters();
    _saveFilterSettings();
  }

  // Fungsi untuk filter merek berdasarkan kriteria
  void filterBrands(Map<String, dynamic> options) {
    // Simpan brandCounts sebelum update filterOptions
    Map<dynamic, dynamic>? brandCounts = filterOptions['brandCounts'];

    // Update filterOptions dengan options baru
    for (var entry in options.entries) {
      filterOptions[entry.key] = entry.value;
    }

    // Kembalikan brandCounts
    if (brandCounts != null) {
      filterOptions['brandCounts'] = brandCounts;
    }

    // If typeId filter is applied, always call filterBrandsByType to ensure correct data
    if (options.containsKey('typeId')) {
      int typeId = options['typeId'] ?? 0;
      filterBrandsByType(typeId).then((_) {
        // Then apply other filters on top of type-filtered results
        _applyFilters();
        _saveFilterSettings();
      });
    } else {
      // No type filter change, just apply other filters
      _applyFilters();
      _saveFilterSettings();
    }
  }

  // Helper method untuk mendapatkan typeId dari typeSlug
  int _getTypeIdFromSlug(String typeSlug) {
    switch (typeSlug.toLowerCase()) {
      case 'mobil':
        return 1;
      case 'sepeda-motor':
        return 2;
      case 'sepeda':
        return 3;
      case 'skuter':
        return 5;
      default:
        return 0;
    }
  }

  // Helper method untuk membuat cache key
  String _getCacheKey(int typeId, int minProductCount) {
    if (typeId == 0) {
      return minProductCount > 0 ? 'all_min_$minProductCount' : 'all';
    } else {
      final typeSlug = getTypeSlug(typeId) ?? 'unknown';
      return minProductCount > 0 ? '${typeSlug}_min_$minProductCount' : typeSlug;
    }
  }

  // BIDIRECTIONAL CACHE SYNCHRONIZATION METHODS
  
  /// Sinkronisasi cache dari parent ke child endpoints
  /// Ketika parent cache diupdate, extract data untuk setiap child type
  void _syncParentToChildCache(String parentKey, List<MerekModel> parentData, int minProductCount) {
    debugPrint('DEBUG: Syncing parent cache to child caches for key: $parentKey');
    
    // PERBAIKAN: Sinkronisasi berdasarkan vehicleTypeCounts yang tersedia di MerekModel
    for (int typeId = 1; typeId <= 5; typeId++) {
      if (typeId == 4) continue; // Skip typeId 4 as it doesn't exist
      
      final childKey = _getCacheKey(typeId, minProductCount);
      
      // Filter data berdasarkan vehicleTypeCounts
      final typeSlug = getTypeSlug(typeId);
      final filteredData = parentData.where((item) {
        if (typeSlug == null) return false;
        
        // PERBAIKAN: Debug logging untuk memastikan filtering bekerja
        if (item.vehicleTypeCounts != null) {
          debugPrint('DEBUG: Brand ${item.name} has vehicleTypeCounts: ${item.vehicleTypeCounts}');
          
          if (item.vehicleTypeCounts!.containsKey(typeSlug)) {
            final typeCount = item.vehicleTypeCounts![typeSlug] ?? 0;
            debugPrint('DEBUG: Brand ${item.name} has $typeCount vehicles for type $typeSlug');
            
            // Apply minProductCount filter if needed
            if (minProductCount > 0) {
              final result = typeCount >= minProductCount;
              debugPrint('DEBUG: MinProductCount filter ($minProductCount): ${item.name} ${result ? 'INCLUDED' : 'EXCLUDED'}');
              return result;
            }
            return typeCount > 0;
          } else {
            debugPrint('DEBUG: Brand ${item.name} does not have type $typeSlug in vehicleTypeCounts');
          }
        } else {
          debugPrint('DEBUG: Brand ${item.name} has no vehicleTypeCounts');
        }
        return false;
      }).toList();
      
      debugPrint('DEBUG: Filtered ${filteredData.length} items from ${parentData.length} parent items for type $typeSlug');
      
      // PERBAIKAN: Selalu update child cache jika ada data dari parent
      if (filteredData.isNotEmpty) {
        _filterCache[childKey] = List<MerekModel>.from(filteredData);
        // Jika parent cache complete, child juga complete
        _filterCacheComplete[childKey] = _filterCacheComplete[parentKey] ?? false;
        _filterHasMoreData[childKey] = false; // Child dari parent yang complete tidak perlu fetch lagi
        _filterCacheLastPage[childKey] = 1;
        
        debugPrint('DEBUG: Synced ${filteredData.length} items to child cache: $childKey');
      } else {
        // Jika tidak ada data untuk type ini, set cache kosong tapi complete
        _filterCache[childKey] = [];
        _filterCacheComplete[childKey] = true;
        _filterHasMoreData[childKey] = false;
        _filterCacheLastPage[childKey] = 1;
        
        debugPrint('DEBUG: No data for type $typeId, set empty complete cache: $childKey');
      }
    }
  }
  
  /// Sinkronisasi cache dari child ke parent endpoint
  /// Ketika child caches diupdate, merge data ke parent cache jika memungkinkan
  void _syncChildToParentCache(int minProductCount) {
    debugPrint('DEBUG: Syncing child caches to parent cache');
    
    final parentKey = _getCacheKey(0, minProductCount);
    
    // Check if parent cache already complete
    if (_filterCacheComplete[parentKey] ?? false) {
      debugPrint('DEBUG: Parent cache already complete, skipping child-to-parent sync');
      return;
    }
    
    // Collect data from all child caches
    final Set<int> allBrandIds = {};
    final Map<int, MerekModel> mergedData = {};
    bool allChildrenComplete = true;
    
    // Check all vehicle type caches
    for (int typeId = 1; typeId <= 5; typeId++) {
      if (typeId == 4) continue; // Skip typeId 4
      
      final childKey = _getCacheKey(typeId, minProductCount);
      
      if (_filterCache.containsKey(childKey)) {
        final childData = _filterCache[childKey]!;
        
        for (final item in childData) {
          if (!allBrandIds.contains(item.id)) {
            allBrandIds.add(item.id);
            mergedData[item.id] = item;
          }
        }
        
        // Check if this child is incomplete
        if (!(_filterCacheComplete[childKey] ?? false)) {
          allChildrenComplete = false;
        }
      } else {
        allChildrenComplete = false;
      }
    }
    
    // Update parent cache if we have enough data
    if (mergedData.isNotEmpty) {
      final currentParentData = _filterCache[parentKey] ?? [];
      final parentDataIds = currentParentData.map((e) => e.id).toSet();
      
      // Add new items from child caches that aren't in parent
      final newItems = mergedData.values.where((item) => !parentDataIds.contains(item.id)).toList();
      
      if (newItems.isNotEmpty) {
        _filterCache[parentKey] = [...currentParentData, ...newItems];
        
        // If all children are complete, mark parent as complete
        if (allChildrenComplete) {
          _filterCacheComplete[parentKey] = true;
          _filterHasMoreData[parentKey] = false;
        }
        
        debugPrint('DEBUG: Synced ${newItems.length} new items to parent cache from children');
        debugPrint('DEBUG: Parent cache now has ${_filterCache[parentKey]!.length} items');
      }
    }
  }
  
  /// Cek dari cache sebelum melakukan API call
  /// Prioritas: child cache -> parent cache -> persistent cache (async)
  List<MerekModel>? _tryGetFromCache(int typeId, int minProductCount) {
    final cacheKey = _getCacheKey(typeId, minProductCount);
    
    // 1. Cek child cache terlebih dahulu
    if (_filterCache.containsKey(cacheKey) && _filterCache[cacheKey]!.isNotEmpty) {
      debugPrint('DEBUG: Found data in child cache for $cacheKey: ${_filterCache[cacheKey]!.length} items');
      return _filterCache[cacheKey];
    }
    
    // 2. Jika child cache kosong dan ini bukan "Semua", cek parent cache
    if (typeId != 0) {
      final parentKey = _getCacheKey(0, minProductCount);
      if (_filterCache.containsKey(parentKey) && _filterCache[parentKey]!.isNotEmpty) {
        debugPrint('DEBUG: Child cache empty, extracting from parent cache for type $typeId');
        
        // PERBAIKAN: Filter parent data by type menggunakan vehicleTypeCounts
        final parentData = _filterCache[parentKey]!;
        final typeSlug = getTypeSlug(typeId);
        
        if (typeSlug != null) {
          final filteredData = parentData.where((brand) {
            if (brand.vehicleTypeCounts != null && brand.vehicleTypeCounts!.containsKey(typeSlug)) {
              final typeCount = brand.vehicleTypeCounts![typeSlug] ?? 0;
              // Apply minProductCount filter if needed
              if (minProductCount > 0) {
                return typeCount >= minProductCount;
              }
              return typeCount > 0;
            }
            return false;
          }).toList();
          
          // PERBAIKAN: Cache the filtered data in child cache dengan status yang benar
          _filterCache[cacheKey] = List<MerekModel>.from(filteredData);
          // Jika parent complete, child juga complete
          _filterCacheComplete[cacheKey] = _filterCacheComplete[parentKey] ?? false;
          _filterHasMoreData[cacheKey] = false; // No more data to fetch from parent
          _filterCacheLastPage[cacheKey] = 1;
          
          debugPrint('DEBUG: Extracted ${filteredData.length} items from parent cache to child cache: $cacheKey');
          return filteredData.isNotEmpty ? filteredData : [];
        }
      }
    }
    
    return null; // No cache available, will check persistent cache separately
  }
  
  /// Load data dari persistent cache (SharedPreferences)
  Future<List<MerekModel>?> _loadFromPersistentCache(int typeId, int minProductCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String cacheKey, timeKey;
      if (typeId == 0) {
        // Parent cache keys
        cacheKey = minProductCount > 0 ? 'merek_data_min_$minProductCount' : 'merek_data';
        timeKey = minProductCount > 0 ? 'merek_cache_time_min_$minProductCount' : 'merek_cache_time';
      } else {
        // Child cache keys  
        final typeSlug = getTypeSlug(typeId) ?? 'unknown';
        if (minProductCount > 0) {
          cacheKey = 'merek_data_type_${typeSlug}_min_$minProductCount';
          timeKey = 'merek_cache_time_type_${typeSlug}_min_$minProductCount';
        } else {
          cacheKey = 'merek_data_type_$typeSlug';
          timeKey = 'merek_cache_time_type_$typeSlug';
        }
      }
      
      final cachedDataString = prefs.getString(cacheKey);
      final cacheTimestamp = prefs.getInt(timeKey);
      
      if (cachedDataString != null && cacheTimestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
        
        // Check if cache is still valid (12 hours)
        if (DateTime.now().difference(cacheTime) < cacheValidity) {
          debugPrint('DEBUG: Loading from persistent cache for typeId: $typeId');
          
          final List<dynamic> cachedData = jsonDecode(cachedDataString);
          final processedItems = await _processMerekItems(cachedData);
          
          if (processedItems.isNotEmpty) {
            // Populate memory cache dengan status yang benar
            final memoryCacheKey = _getCacheKey(typeId, minProductCount);
            
            // Cek apakah data sudah ada di memory cache untuk prevent duplikasi
            if (!_filterCache.containsKey(memoryCacheKey) || 
                _filterCache[memoryCacheKey]!.isEmpty) {
              
              _filterCache[memoryCacheKey] = List<MerekModel>.from(processedItems);
              _filterCacheComplete[memoryCacheKey] = true; // Mark as complete from persistent cache
              _filterHasMoreData[memoryCacheKey] = false; // No more data needed
              _filterCacheLastPage[memoryCacheKey] = 1; // Mark as loaded
              
              debugPrint('DEBUG: Loaded ${processedItems.length} items from persistent cache to memory cache');
              return processedItems;
            } else {
              debugPrint('DEBUG: Memory cache already exists for $memoryCacheKey, skipping persistent load');
              return _filterCache[memoryCacheKey];
            }
          }
        } else {
          debugPrint('DEBUG: Persistent cache expired for typeId: $typeId');
        }
      } else {
        debugPrint('DEBUG: No persistent cache found for typeId: $typeId');
      }
    } catch (e) {
      debugPrint('ERROR: Failed to load from persistent cache: $e');
    }
    
    return null;
  }

  Future<void> filterBrandsByType(int typeId) async {
    filterOptions['typeId'] = typeId;
    final minProductCount = filterOptions['minProductCount'] ?? 0;
    final cacheKey = _getCacheKey(typeId, minProductCount);

    debugPrint('DEBUG: filterBrandsByType called with typeId: $typeId, cacheKey: $cacheKey');
    debugPrint('DEBUG: Cache exists: ${_filterCache.containsKey(cacheKey)}');
    debugPrint('DEBUG: Cache complete: ${_filterCacheComplete[cacheKey] ?? false}');
    debugPrint('DEBUG: Cache items count: ${_filterCache[cacheKey]?.length ?? 0}');
    debugPrint('DEBUG: Current state before reset - currentPage: $currentPage, hasMoreData: ${hasMoreData.value}');

    // PERBAIKAN: Stop semua background fetch yang sedang berjalan untuk menghindari konflik
    _backgroundFetchInProgress.clear();

    // PERBAIKAN: Reset state dan clear display list sebelum proses apapun
    merekList.clear();
    filteredMerekList.clear();
    isLoading.value = true;
    currentPage = 1;
    hasMoreData.value = true;
    
    debugPrint('DEBUG: State after reset - currentPage: $currentPage, hasMoreData: ${hasMoreData.value}');

    // BIDIRECTIONAL CACHE: Try to get data from cache (child first, then parent, then persistent)
    final cachedData = _tryGetFromCache(typeId, minProductCount);
    
    if (cachedData != null) {
      debugPrint('DEBUG: Loading from bidirectional cache for $cacheKey, ${cachedData.length} items');
      
      // PERBAIKAN: Jika data dari cache kosong, tapi parent cache ada data, extract dulu
      if (cachedData.isEmpty && typeId > 0) {
        final parentKey = _getCacheKey(0, minProductCount);
        if (_filterCache.containsKey(parentKey) && _filterCache[parentKey]!.isNotEmpty) {
          debugPrint('DEBUG: Child cache empty but parent exists, triggering sync');
          _syncParentToChildCache(parentKey, _filterCache[parentKey]!, minProductCount);
          
          // Try get from cache again after sync
          final syncedData = _filterCache[cacheKey];
          if (syncedData != null && syncedData.isNotEmpty) {
            debugPrint('DEBUG: Successfully synced ${syncedData.length} items to child cache');
            merekList.value = List<MerekModel>.from(syncedData);
            hasMoreData.value = false; // Synced data is complete
            currentPage = 1;
            isLoading.value = false;
            _applyFilters();
            return;
          }
        }
      }
      
      // Load data from cache dengan replace untuk prevent duplicate
      merekList.value = List<MerekModel>.from(cachedData);
      hasMoreData.value = _filterHasMoreData[cacheKey] ?? true;
      currentPage = (_filterCacheLastPage[cacheKey] ?? 0) + 1;
      
      // If cache is complete, set hasMoreData to false
      if (_filterCacheComplete[cacheKey] ?? false) {
        hasMoreData.value = false;
        debugPrint('DEBUG: Cache is complete for $cacheKey, no more data to fetch');
      }
      
      // PERBAIKAN: Set loading to false setelah data di-load dari cache
      isLoading.value = false;
      _applyFilters();
      
      // Jika cache tidak complete dan data tidak kosong, lanjutkan fetch data di background
      if (!(_filterCacheComplete[cacheKey] ?? false) && cachedData.isNotEmpty) {
        debugPrint('DEBUG: Cache incomplete for $cacheKey, continuing fetch in background');
        _fetchMoreDataInBackground(typeId, minProductCount, cacheKey);
      }
      return;
    }

    // Try persistent cache as async fallback
    final persistentData = await _loadFromPersistentCache(typeId, minProductCount);
    if (persistentData != null && persistentData.isNotEmpty) {
      debugPrint('DEBUG: Loading from persistent cache for $cacheKey, ${persistentData.length} items');
      
      merekList.value = List<MerekModel>.from(persistentData);
      hasMoreData.value = false; // Persistent cache assumed complete
      currentPage = 1;
      
      isLoading.value = false;
      _applyFilters();
      return;
    }

    // Jika tidak ada cache, fetch data dari server
    debugPrint('DEBUG: No cache found, fetching from server for $cacheKey');
    
    try {
      if (typeId == 0) {
        // Untuk "Semua", fetch semua brand
        debugPrint('DEBUG: Fetching Semua data');
        await fetchMerek(isRefresh: true);
      } else {
        // Untuk type spesifik, fetch dengan endpoint vehicle_type
        final typeSlug = getTypeSlug(typeId);
        if (typeSlug != null) {
          debugPrint('DEBUG: Fetching data for type slug: $typeSlug');
          await fetchMerekByType(typeSlug, isRefresh: true);
        } else {
          // Fallback jika typeSlug tidak ditemukan
          debugPrint('WARNING: TypeSlug not found for typeId: $typeId');
          isLoading.value = false;
          // Show error state but don't throw exception
          return;
        }
      }
    } catch (e) {
      debugPrint('ERROR: Failed to fetch data in filterBrandsByType: $e');
      // Ensure loading is set to false even if there's an error
      isLoading.value = false;
      
      // Try to show any existing data instead of error state
      if (merekList.isNotEmpty) {
        debugPrint('DEBUG: Using existing merekList data after error');
        _applyFilters();
      }
      // Don't rethrow the exception to prevent showing error dialog
    }
  }

  // Method untuk fetch data di background tanpa blocking UI
  void _fetchMoreDataInBackground(int typeId, int minProductCount, String cacheKey) async {
    // Prevent concurrent background fetching for same cache key
    if (_backgroundFetchInProgress.contains(cacheKey)) {
      debugPrint('DEBUG: Background fetch already in progress for $cacheKey');
      return;
    }
    
    // Check if cache is already complete
    if (_filterCacheComplete[cacheKey] ?? false) {
      debugPrint('DEBUG: Cache already complete for $cacheKey, skipping background fetch');
      return;
    }
    
    _backgroundFetchInProgress.add(cacheKey);
    debugPrint('DEBUG: Starting background fetch for $cacheKey');
    
    try {
      // Set current page based on cache
      if (_filterCacheLastPage.containsKey(cacheKey)) {
        currentPage = (_filterCacheLastPage[cacheKey] ?? 0) + 1;
        debugPrint('DEBUG: Background fetch currentPage set to $currentPage for $cacheKey');
      }
      
      if (typeId == 0) {
        // Continue fetching "Semua" data
        await fetchMerek(isRefresh: false);
      } else {
        final typeSlug = getTypeSlug(typeId);
        if (typeSlug != null) {
          await fetchMerekByType(typeSlug, isRefresh: false);
        }
      }
    } finally {
      _backgroundFetchInProgress.remove(cacheKey);
      debugPrint('DEBUG: Background fetch completed for $cacheKey');
    }
  }

  // New method to fetch brands by type with pagination support
  Future<void> fetchMerekByType(String typeSlug, {bool isRefresh = false}) async {
    if (isLoading.value && !isRefresh) return;

    debugPrint('DEBUG: Starting fetchMerekByType for $typeSlug, isRefresh: $isRefresh, currentPage: $currentPage');

    isLoading.value = true;

    try {
      int pageToFetch = isRefresh ? 1 : currentPage;
      final minProductCount = filterOptions['minProductCount'] ?? 0;
      
      debugPrint('DEBUG: fetchMerekByType - pageToFetch: $pageToFetch, minProductCount: $minProductCount');
      
      // PERBAIKAN: Gunakan endpoint baru dengan parameter vehicle_type
      String url = '$prodUrl/merek?page=$pageToFetch&per_page=$pageSize&vehicle_type=$typeSlug';
      if (minProductCount > 0) {
        url += '&min_vehicles_count=$minProductCount';
      }
      
      debugPrint('DEBUG: Fetching brands by type URL: $url');
      
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      debugPrint('DEBUG: /merek by type API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        
        // Handle pagination info
        final bool hasMorePages = data['has_more_pages'] ?? false;
        final int total = data['total'] ?? 0;
        hasMoreData.value = hasMorePages;
        totalBrandsCount.value = total;
        
        debugPrint('DEBUG: Received ${items.length} items for type $typeSlug');

        // Process items from API
        final processedItems = await _processMerekItems(items);
        debugPrint('DEBUG: Processed ${processedItems.length} items for type $typeSlug');

        // Update cache untuk type-specific filter
        final typeId = _getTypeIdFromSlug(typeSlug);
        final cacheKey = _getCacheKey(typeId, minProductCount);
        
        if (isRefresh) {
          // PERBAIKAN: Untuk refresh, selalu replace data lama dengan data baru
          merekList.value = processedItems;
          currentPage = 2; // Next page for infinite scroll
          debugPrint('DEBUG: Refreshed data for type $typeSlug, merekList now has ${merekList.length} items');
          
          // Replace cache dengan data baru (tanpa duplikasi)
          _filterCache[cacheKey] = List<MerekModel>.from(processedItems);
        } else if (!isRefresh) {
          // Pagination - append data tanpa duplikasi
          final existingIds = merekList.map((e) => e.id).toSet();
          final newItems = processedItems.where((item) => !existingIds.contains(item.id)).toList();
          
          if (newItems.isNotEmpty) {
            merekList.addAll(newItems);
            currentPage++;
            debugPrint('DEBUG: Added ${newItems.length} new items for type $typeSlug, merekList now has ${merekList.length} items');
            
            if (!_filterCache.containsKey(cacheKey)) {
              _filterCache[cacheKey] = [];
            }
            
            // Prevent duplicates in cache too
            final existingCacheIds = _filterCache[cacheKey]!.map((e) => e.id).toSet();
            final newCacheItems = newItems.where((item) => !existingCacheIds.contains(item.id)).toList();
            _filterCache[cacheKey]!.addAll(newCacheItems);
          } else {
            debugPrint('DEBUG: No new items to add for type $typeSlug, all items already exist');
          }
        }
        
        _filterCacheLastPage[cacheKey] = currentPage - 1;
        _filterHasMoreData[cacheKey] = hasMorePages;
        _filterCacheComplete[cacheKey] = !hasMorePages; // Mark complete jika tidak ada lagi data
        
        debugPrint('DEBUG: Updated cache for $cacheKey (type: $typeSlug), total items: ${_filterCache[cacheKey]?.length ?? 0}');

        // BIDIRECTIONAL CACHE: Sinkronisasi child cache ke parent cache
        _syncChildToParentCache(minProductCount);

        // Apply other filters (search, sorting, etc.)
        _applyFilters();
        
        // PERBAIKAN: Save to cache dengan duplikasi prevention
        if (isRefresh) {
          // Save data to cache with type and filter key
          await _updateCacheWithTypeFilter(items, typeSlug, minProductCount);
        }
        
      } else {
        debugPrint('ERROR: API Error for type $typeSlug: ${response.statusCode}');
        debugPrint('ERROR: Response body: ${response.body}');
        
        // PERBAIKAN: Jangan throw error yang menyebabkan "Gagal memuat data" 
        // Instead, try to use existing cache if available
        if (isRefresh && merekList.isEmpty) {
          // Try to load from cache as fallback
          final typeId = _getTypeIdFromSlug(typeSlug);
          final cachedData = _tryGetFromCache(typeId, minProductCount);
          if (cachedData != null && cachedData.isNotEmpty) {
            debugPrint('DEBUG: Using cached data as fallback for type $typeSlug');
            merekList.value = List<MerekModel>.from(cachedData);
            _applyFilters();
            return;
          }
        }
        
        // Only show error if no cache fallback available
        if (merekList.isEmpty) {
          ErrorHandlerService.handleError(
            AppException(
              message: 'Gagal memuat data merek. Silakan coba lagi nanti.',
              type: ErrorType.server,
              statusCode: response.statusCode,
            ),
            showToUser: true,
          );
        }
      }
    } catch (e) {
      debugPrint('ERROR: Exception in fetchMerekByType: $e');
      ErrorHandlerService.handleError(
        AppException(
          message: 'Terjadi kesalahan saat memuat data. Silakan coba lagi.',
          type: ErrorType.unknown,
        ),
        showToUser: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String? getTypeSlug(int typeId) {
    switch (typeId) {
      case 1:
        return 'mobil';
      case 2:
        return 'sepeda-motor';
      case 3:
        return 'sepeda';
      case 5:
        return 'skuter';
      default:
        return null;
    }
  }

  // Method untuk clear cache
  void clearFilterCache() {
    debugPrint('DEBUG: Clearing all filter cache');
    _filterCache.clear();
    _filterCacheComplete.clear();
    _filterCacheLastPage.clear();
    _filterHasMoreData.clear();
    _backgroundFetchInProgress.clear(); // Clear background fetch tracking
  }

  // Method untuk clear cache specific key
  void clearFilterCacheForKey(String cacheKey) {
    debugPrint('DEBUG: Clearing cache for key: $cacheKey');
    _filterCache.remove(cacheKey);
    _filterCacheComplete.remove(cacheKey);
    _filterCacheLastPage.remove(cacheKey);
    _filterHasMoreData.remove(cacheKey);
    _backgroundFetchInProgress.remove(cacheKey); // Clear background fetch tracking for this key
  }

  // Method untuk populate cache type-specific dari data 'Semua' yang sudah complete
  void _populateTypeSpecificCaches(int minProductCount) {
    final semuaCacheKey = _getCacheKey(0, minProductCount);
    final semuaData = _filterCache[semuaCacheKey];
    
    if (semuaData == null || semuaData.isEmpty) return;
    
    // Define type IDs yang akan di-populate
    final typeIds = [1, 2, 3, 5]; // Mobil, Sepeda Motor, Sepeda, Skuter
    
    for (final typeId in typeIds) {
      final typeCacheKey = _getCacheKey(typeId, minProductCount);
      
      // Filter data untuk type ini
      final filteredData = semuaData.where((merek) {
        final vehicleTypeCounts = merek.vehicleTypeCounts;
        if (vehicleTypeCounts == null) return false;
        
        return vehicleTypeCounts.containsKey(typeId) && 
               vehicleTypeCounts[typeId]! > 0 &&
               (minProductCount == 0 || vehicleTypeCounts[typeId]! >= minProductCount);
      }).toList();
      
      // Populate cache untuk type ini
      _filterCache[typeCacheKey] = List<MerekModel>.from(filteredData);
      _filterCacheComplete[typeCacheKey] = true;
      _filterHasMoreData[typeCacheKey] = false;
      _filterCacheLastPage[typeCacheKey] = 1;
      
      debugPrint('DEBUG: Populated cache for type $typeId: ${filteredData.length} items');
    }
  }

  // Method untuk sinkronisasi data baru dari 'Semua' ke cache type-specific
  void _syncNewDataWithTypeSpecificCaches(List<MerekModel> newItems, int minProductCount) {
    final typeIds = [1, 2, 3, 5]; // Mobil, Sepeda Motor, Sepeda, Skuter
    
    for (final typeId in typeIds) {
      final typeCacheKey = _getCacheKey(typeId, minProductCount);
      
      // Skip jika cache type ini belum ada
      if (!_filterCache.containsKey(typeCacheKey)) continue;
      
      final typeCache = _filterCache[typeCacheKey]!;
      
      // Filter item baru yang sesuai dengan type ini
      final relevantItems = newItems.where((merek) {
        final vehicleTypeCounts = merek.vehicleTypeCounts;
        if (vehicleTypeCounts == null) return false;
        
        return vehicleTypeCounts.containsKey(typeId) && 
               vehicleTypeCounts[typeId]! > 0 &&
               (minProductCount == 0 || vehicleTypeCounts[typeId]! >= minProductCount);
      }).toList();
      
      // Tambahkan/update item yang relevan ke cache type
      for (final newItem in relevantItems) {
        final existingIndex = typeCache.indexWhere((item) => item.id == newItem.id);
        if (existingIndex == -1) {
          typeCache.add(newItem);
          debugPrint('DEBUG: Added ${newItem.name} to type $typeId cache');
        } else {
          typeCache[existingIndex] = newItem;
          debugPrint('DEBUG: Updated ${newItem.name} in type $typeId cache');
        }
      }
      
      debugPrint('DEBUG: Synced ${relevantItems.length} items with type $typeId cache');
    }
  }

  // Reset semua filter dan pencarian
  void resetFilters() {
    searchQuery.value = '';
    // Simpan brandCounts sebelum mereset filterOptions
    Map<dynamic, dynamic>? brandCounts = filterOptions['brandCounts'];

    filterOptions.clear();

    // Kembalikan brandCounts setelah clear
    if (brandCounts != null) {
      filterOptions['brandCounts'] = brandCounts;
    }

    sortBy.value = 'name';
    sortOrder.value = 'asc';
    isSearching.value = false; // Tutup mode pencarian
    filteredMerekList.clear();
    
    // Clear cache karena filter berubah
    clearFilterCache();
    
    _applyFilters();
    _saveFilterSettings();
  }

  // Apply all active filters
  void _applyFilters() {
    List<MerekModel> filtered;
    final int? activeTypeId = filterOptions['typeId'];
    final int minCount = filterOptions['minProductCount'] ?? 0;

    // Start with full list as base
    filtered = List<MerekModel>.from(merekList);

    // Apply type filter based on vehicle_type_counts
    if (activeTypeId != null && activeTypeId > 0) {
      final typeSlug = getTypeSlug(activeTypeId);
      if (typeSlug != null) {
        debugPrint('DEBUG: Applying client-side filter for type: $typeSlug');
        filtered = filtered.where((brand) {
          // Check if this brand has vehicles of the selected type in vehicle_type_counts
          // This is additional client-side filtering on top of server-side filtering
          // to ensure accuracy when data comes from cache or mixed sources
          if (brand.vehicleTypeCounts != null && brand.vehicleTypeCounts!.containsKey(typeSlug)) {
            final typeCount = brand.vehicleTypeCounts![typeSlug] ?? 0;
            // If minCount is applied for specific type, check against type count
            if (minCount > 0) {
              return typeCount >= minCount;
            }
            return typeCount > 0;
          }
          return false; // Don't show if no vehicle_type_counts for this type
        }).toList();
        debugPrint('DEBUG: Filtered list length after type filter: ${filtered.length}');
      }
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((brand) => 
        brand.name.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }

    // Apply minimum vehicle count filter for "Semua" only
    if (minCount > 0 && (activeTypeId == null || activeTypeId == 0)) {
      // For "Semua", check total vehicles_count
      filtered = filtered.where((brand) => brand.vehiclesCount >= minCount).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result;
      if (sortBy.value == 'vehicles_count') {
        result = b.vehiclesCount.compareTo(a.vehiclesCount);
      } else {
        result = a.name.compareTo(b.name);
      }
      return sortOrder.value == 'asc' ? result : -result;
    });

    filteredMerekList.value = filtered;
    debugPrint('DEBUG: Final filtered list length: ${filtered.length}');
  }

  // Search state
  var isSearchLoading = false.obs;
  var searchResults = <String, List<dynamic>>{}.obs;

  // Toggle search mode
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchQuery.value = '';
      searchResults.clear();
      _applyFilters(); // Reset tampilan ketika search ditutup
    }
  }

  // Search history
  var searchHistory = <String>[].obs;
  final int maxHistoryItems = 10;

  // Real-time search function
  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearchLoading.value = true;
    searchQuery.value = query;

    try {
      // Add to history
      addToSearchHistory(query);

      // Search in brands
      final brandResults =
          merekList
              .where(
                (brand) =>
                    brand.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      Map<String, List<dynamic>> results = {};
      if (brandResults.isNotEmpty) {
        results['MEREK'] = brandResults;
      }

      // Search in vehicles from each endpoint
      final vehicleResults = <Map<String, dynamic>>[];
      for (var endpoint in typeEndpoints.entries) {
        try {
          final response = await _appTokenService.requestWithAutoRefresh(
            requestFn: (appKey) => http.get(
              Uri.parse('${endpoint.value}?search=$query'),
              headers: {'Accept': 'application/json', 'x-app-key': appKey},
            ),
            platform: "android",
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['vehicles'] != null) {
              final vehicles =
                  (data['vehicles'] as List)
                      .where(
                        (v) => v['name'].toString().toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      )
                      .map((v) => v as Map<String, dynamic>)
                      .toList();
              if (vehicles.isNotEmpty) {
                vehicleResults.addAll(vehicles);
              }
            }
          }
        } catch (e) {
          debugPrint('Error searching vehicles from ${endpoint.key}: $e');
        }
      }

      if (vehicleResults.isNotEmpty) {
        results['KENDARAAN'] = vehicleResults;
      }

      searchResults.value = results;
    } catch (e) {
      debugPrint('Error in performSearch: $e');
    } finally {
      isSearchLoading.value = false;
    }
  }
  
  // Reset search
  void resetSearch() {
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  // Load search history
  Future<void> _loadSearchHistory() async {
    try {
      final file = await _getLocalFile('search_history.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final List<dynamic> history = jsonDecode(contents);
        searchHistory.value = List<String>.from(history);
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  // Save search history
  Future<void> _saveSearchHistory() async {
    try {
      final file = await _getLocalFile('search_history.json');
      await file.writeAsString(jsonEncode(searchHistory.toList()));
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  // Add to search history
  void addToSearchHistory(String query) {
    if (query.isEmpty) return;

    // Remove if exists (to move to top)
    searchHistory.remove(query);

    // Add to beginning of list
    searchHistory.insert(0, query);

    // Keep only maxHistoryItems
    if (searchHistory.length > maxHistoryItems) {
      searchHistory.removeRange(maxHistoryItems, searchHistory.length);
    }

    _saveSearchHistory();
  }

  // Remove from search history
  void removeFromSearchHistory(String query) {
    searchHistory.remove(query);
    _saveSearchHistory();
  }

  // Clear search history
  void clearSearchHistory() {
    searchHistory.clear();
    _saveSearchHistory();
  }

  String getTypeName(int typeId) {
    return vehicleTypeNames[typeId] ?? 'Unknown';
  }

  final Map<String, String> typeEndpoints = {
    'mobil': '$prodUrl/tipe/mobil',
    'sepeda-motor': '$prodUrl/tipe/sepeda-motor',
    'sepeda': '$prodUrl/tipe/sepeda',
    'skuter': '$prodUrl/tipe/skuter',
  };

  // Method untuk mendapatkan filtered count berdasarkan vehicles_count dari merek
  int getFilteredTypeCount(int typeId, int minProductCount) {
    try {
      // Get brands_count from /tipe endpoint for this typeId
      final brandCounts = filterOptions['brandCounts'];
      if (brandCounts != null && brandCounts[typeId] != null) {
        final totalBrandsForType = brandCounts[typeId] as int;
        
        if (minProductCount <= 0) {
          // No minProductCount filter, return original brands_count
          return totalBrandsForType;
        }
        
        // For minProductCount filter, we need to make API call or estimate
        // Since we can't make API call in this sync method, we'll estimate
        // based on the proportion in current merekList
        
        if (typeId == 0) {
          // For "Semua", count all brands that meet minProductCount
          return merekList.where((brand) => 
            brand.vehiclesCount >= minProductCount).length;
        } else {
          // For specific type, estimate based on current data proportion
          final totalCurrentBrands = merekList.length;
          final filteredCurrentBrands = merekList.where((brand) => 
            brand.vehiclesCount >= minProductCount).length;
          
          if (totalCurrentBrands > 0) {
            final proportion = filteredCurrentBrands / totalCurrentBrands;
            return (totalBrandsForType * proportion).round();
          }
        }
      }
      
      return 0;
    } catch (e) {
      debugPrint('Error calculating filtered type count: $e');
      return 0;
    }
  }

  // Method untuk mendapatkan total count semua jenis setelah minProductCount filter
  int getTotalFilteredCount() {
    final minProductCount = filterOptions['minProductCount'] ?? 0;
    if (minProductCount <= 0) {
      return merekList.length;
    }
    
    return merekList.where((brand) => 
      brand.vehiclesCount >= minProductCount).length;
  }

  // Method untuk cek apakah semua type count bernilai 0 setelah filtering
  bool areAllTypeCountsZero() {
    final minProductCount = filterOptions['minProductCount'] ?? 0;
    if (minProductCount <= 0) {
      return false; // If no filter applied, counts shouldn't be zero
    }
    
    // Check if any type has count > 0
    for (int typeId in [1, 2, 3, 5]) {
      if (getFilteredTypeCount(typeId, minProductCount) > 0) {
        return false;
      }
    }
    
    return true;
  }

  // Method untuk load data tipe yang dipanggil dari jelajah.dart
  Future<void> loadTypeData() async {
    try {
      // TODO: Remove debug prints later
      debugPrint('DEBUG: Starting loadTypeData');
      
      // Load type counts dari cache dulu
      await _loadTypeCountsFromCache();
      debugPrint('DEBUG: Type counts loaded from cache');

      // Jika tidak ada di cache atau sudah kadaluarsa, ambil dari API
      if ((filterOptions['brandCounts'] as Map<dynamic, dynamic>?)?.isEmpty ??
          true) {
        debugPrint('DEBUG: No type counts in filterOptions, fetching from API');
        await _fetchTypeCountsFromApi();
      } else {
        debugPrint('DEBUG: Type counts already available in filterOptions: ${filterOptions['brandCounts']}');
      }
    } catch (e) {
      debugPrint('ERROR: Error loading type data: $e');
    }
  }

  // Cache untuk menyimpan hasil perhitungan filtered count
  final Map<String, int> _filteredCountCache = {};

  // Method untuk menghitung filtered count secara synchronous
  int getFilteredTypeCountSync(int typeId, int minProductCount) {
    try {
      if (minProductCount <= 0) {
        // Return original count if no minProductCount filter
        final brandCounts = filterOptions['brandCounts'];
        if (brandCounts != null && brandCounts[typeId] != null) {
          return brandCounts[typeId] as int;
        }
        return 0;
      }

      // Check cache first
      final cacheKey = 'type_${typeId}_min_$minProductCount';
      if (_filteredCountCache.containsKey(cacheKey)) {
        return _filteredCountCache[cacheKey]!;
      }

      // Calculate and cache the result
      _updateFilteredCountCache();
      
      return _filteredCountCache[cacheKey] ?? 0;
    } catch (e) {
      debugPrint('Error calculating filtered type count sync: $e');
      // Return original count on error
      final brandCounts = filterOptions['brandCounts'];
      if (brandCounts != null && brandCounts[typeId] != null) {
        return brandCounts[typeId] as int;
      }
      return 0;
    }
  }

  // Ensure filtered count cache is populated (synchronous version)
  void ensureFilteredCountCache() {
    // Check if cache is already populated
    if (_filteredCountCache.isNotEmpty) {
      return;
    }

    // Populate cache synchronously using available data
    try {
      // For each type, calculate counts based on available brandCounts and merekList
      for (int typeId in [1, 2, 3, 5]) {
        // Get original count from brandCounts
        final brandCounts = filterOptions['brandCounts'];
        if (brandCounts != null && brandCounts[typeId] != null) {
          final originalCount = brandCounts[typeId] as int;
          
          // If we don't have detailed brand data for this type yet,
          // calculate proportional estimates for now
          for (int minCount = 1; minCount <= 10; minCount++) {
            final totalBrands = merekList.length;
            final filteredBrands = merekList.where((brand) => brand.vehiclesCount >= minCount).length;
            
            if (totalBrands > 0) {
              final proportion = filteredBrands / totalBrands;
              final estimatedCount = (originalCount * proportion).round();
              _filteredCountCache['type_${typeId}_min_$minCount'] = estimatedCount;
            } else {
              _filteredCountCache['type_${typeId}_min_$minCount'] = 0;
            }
          }
        }
      }
      
      // Schedule async update for more accurate data
      Future.microtask(() => _updateFilteredCountCache());
    } catch (e) {
      debugPrint('Error ensuring filtered count cache: $e');
    }
  }

  // Update cache untuk filtered count
  void _updateFilteredCountCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (int typeId in [1, 2, 3, 5]) {
        final cacheKey = 'type_brands_$typeId';
        final cacheStr = prefs.getString(cacheKey);
        
        if (cacheStr != null) {
          final List<int> brandIds = (jsonDecode(cacheStr) as List<dynamic>)
              .map((id) => id as int)
              .toList();

          // Calculate counts for different minProductCount values
          for (int minCount = 1; minCount <= 10; minCount++) {
            int count = 0;
            for (int brandId in brandIds) {
              try {
                final brand = merekList.firstWhere((b) => b.id == brandId);
                if (brand.vehiclesCount >= minCount) {
                  count++;
                }
              } catch (e) {
                // Brand not found, skip
                continue;
              }
            }
            _filteredCountCache['type_${typeId}_min_$minCount'] = count;
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating filtered count cache: $e');
    }
  }
}
