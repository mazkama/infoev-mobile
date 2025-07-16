import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:infoev/app/modules/explore/model/MerekModel.dart';
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
  final Duration cacheValidity = const Duration(hours: 2);

  // AppTokenService untuk x-app-key
  late final AppTokenService _appTokenService;
  
  // Search and filter state
  var isSearching = false.obs;
  var searchQuery = ''.obs;
  var sortBy = 'name'.obs;
  var sortOrder = 'asc'.obs;
  var filterOptions = <String, dynamic>{}.obs;

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
        await _fetchTypeCountsFromApi();
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }
  }

  Future<void> _loadTypeCountsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsStr = prefs.getString('type_counts');
      final timestamp = prefs.getInt('type_counts_timestamp');

      if (countsStr != null && timestamp != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (cacheAge < cacheValidity.inMilliseconds) {
          final counts = Map<int, int>.from(jsonDecode(countsStr));
          filterOptions['brandCounts'] = counts;
          update();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading type counts from cache: $e');
    }
  }

  Future<void> _fetchTypeCountsFromApi() async {
    try {
      Map<int, int> counts = {};
      final prefs = await SharedPreferences.getInstance();

      // Fetch counts for all types
      for (var typeId in [1, 2, 3, 5]) {
        final typeSlug = getTypeSlug(typeId);
        if (typeSlug != null) {
          final response = await _appTokenService.requestWithAutoRefresh(
            requestFn: (appKey) => http.get(
              Uri.parse('$prodUrl/tipe/$typeSlug'),
              headers: {'Accept': 'application/json', 'x-app-key': appKey},
            ),
            platform: "android",
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List<dynamic> vehicles = data['vehicles'] ?? [];

            final Set<int> uniqueBrandIds = {};
            for (var vehicle in vehicles) {
              if (vehicle['brand_id'] != null) {
                uniqueBrandIds.add(vehicle['brand_id'] as int);
              }
            }

            counts[typeId] = uniqueBrandIds.length;
          }
        }
      }

      if (counts.isNotEmpty) {
        // Update state
        filterOptions['brandCounts'] = counts;

        // Save to cache
        await prefs.setString('type_counts', jsonEncode(counts));
        await prefs.setInt(
          'type_counts_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );

        update();
      }
    } catch (e) {
      debugPrint('Error fetching type counts: $e');
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
            final List<MerekModel> list =
                items.map((item) => MerekModel.fromJson(item)).toList();
            merekList.value = list;
            _applyFilters();
            await _loadBrandImageScales();
            dataLoaded = true;
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
            final List<MerekModel> list =
                data.map((item) => MerekModel.fromJson(item)).toList();
            merekList.value = list;
            _applyFilters();
            dataLoaded = true;
          }
        }
      }

      // Jika tidak ada data tersimpan, load dari API
      if (!dataLoaded) {
        await fetchMerek(isRefresh: true);
      } else {
        // Jika data sudah diload, update di background
        fetchMerek(isRefresh: true);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      await fetchMerek(isRefresh: true);
    } finally {
      isLoading.value = false;
    }
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
    await fetchMerek(isRefresh: true);
    isRefreshing.value = false;
  }

  Future<void> fetchMerek({bool isRefresh = false}) async {
    if (isLoading.value && !isRefresh) return;

    isLoading.value = true;

    try {
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse('$prodUrl/merek'),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        // Proses item merek untuk mendapatkan banner
        final processedItems = await _processMerekItems(items);

        if (isRefresh) {
          merekList.value = processedItems;
        } else {
          merekList.addAll(processedItems);
        }

        _applyFilters();

        if (isRefresh) {
          // Simpan data ke cache dan file lokal
          _updateCache(items);
        }

        hasMoreData.value = false; // Tidak ada paging di API
      } else {
        debugPrint('API Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<MerekModel>> _processMerekItems(List<dynamic> items) async {
    try {
      final List<MerekModel> result = [];

      for (var item in items) {
        MerekModel merek = MerekModel.fromJson(item);

        try {
          // Dapatkan banner untuk merek ini
          final String? banner = await fetchBanner(merek.slug);

          if (banner != null) {
            merek = merek.copyWith(banner: banner);
          }

          result.add(merek);
        } catch (e) {
          // Jika gagal mengambil banner, tetap tambahkan merek tanpa banner
          debugPrint('Error fetching banner for ${merek.name}: $e');
          result.add(merek);
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error in _processMerekItems: $e');
      return [];
    }
  }

  Future<void> _updateCache(List<dynamic> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('merek_data', jsonEncode(items));
      await prefs.setInt(
        'merek_cache_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error updating cache: $e');
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

    _applyFilters();
    _saveFilterSettings();
  }

  Future<void> filterBrandsByType(int typeId) async {
    filterOptions['typeId'] = typeId;

    if (typeId == 0) {
      filteredMerekList.clear();
      return;
    }

    final typeSlug = getTypeSlug(typeId);
    if (typeSlug != null) {
      try {
        // Cek cache dulu
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'type_brands_$typeId';
        final cacheStr = prefs.getString(cacheKey);
        final cacheTime = prefs.getInt('${cacheKey}_timestamp');

        Set<int> brandIds = {};

        if (cacheStr != null && cacheTime != null) {
          final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
          if (cacheAge < cacheValidity.inMilliseconds) {
            brandIds =
                (jsonDecode(cacheStr) as List<dynamic>)
                    .map((id) => id as int)
                    .toSet();
          }
        }

        if (brandIds.isEmpty) {
          final response = await _appTokenService.requestWithAutoRefresh(
            requestFn: (appKey) => http.get(
              Uri.parse('$prodUrl/tipe/$typeSlug'),
              headers: {'Accept': 'application/json', 'x-app-key': appKey},
            ),
            platform: "android",
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List<dynamic> vehicles = data['vehicles'] ?? [];

            for (var vehicle in vehicles) {
              if (vehicle['brand_id'] != null) {
                brandIds.add(vehicle['brand_id'] as int);
              }
            }

            // Save to cache
            await prefs.setString(cacheKey, jsonEncode(brandIds.toList()));
            await prefs.setInt(
              '${cacheKey}_timestamp',
              DateTime.now().millisecondsSinceEpoch,
            );
          }
        }

        // Filter merek list
        filteredMerekList.value =
            merekList.where((brand) => brandIds.contains(brand.id)).toList();

        // Update count in brandCounts
        final counts =
            (filterOptions['brandCounts'] ?? {}) as Map<dynamic, dynamic>;
        counts[typeId] = brandIds.length;
        filterOptions['brandCounts'] = counts;

        update();
      } catch (e) {
        debugPrint('Error filtering brands by type: $e');
        filteredMerekList.clear();
      }
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
    _applyFilters();
    _saveFilterSettings();
  }

  // Apply all active filters
  void _applyFilters() {
    List<MerekModel> filtered = List<MerekModel>.from(merekList);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (brand) => brand.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply minimum vehicle count filter
    if (filterOptions.containsKey('minProductCount')) {
      final int minCount = filterOptions['minProductCount'];
      if (minCount > 0) {
        filtered =
            filtered.where((brand) => brand.vehiclesCount >= minCount).toList();
      }
    }

    // Apply sorting
    filtered.sort((a, b) {
      int result;
      if (sortBy.value == 'vehicles_count') {
        result = b.vehiclesCount.compareTo(
          a.vehiclesCount,
        ); // Descending for count
      } else {
        result = a.name.compareTo(b.name);
      }
      return sortOrder.value == 'asc' ? result : -result;
    });

    filteredMerekList.value = filtered;
  }

  Future<String?> fetchBanner(String slug) async {
    try {
      // Coba ambil dari cache dulu
      final prefs = await SharedPreferences.getInstance();
      final cachedBanner = prefs.getString('banner_$slug');
      final cacheTime = prefs.getInt('banner_${slug}_time');

      if (cachedBanner != null && cacheTime != null) {
        final DateTime cacheDateTime = DateTime.fromMillisecondsSinceEpoch(
          cacheTime,
        );
        if (DateTime.now().difference(cacheDateTime) < cacheValidity) {
          return cachedBanner;
        }
      }

      // Coba ambil dari file lokal
      final file = await _getLocalFile('banner_$slug.json');
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);

        final int? timestamp = data['timestamp'];
        final String? banner = data['banner'];

        if (timestamp != null && banner != null) {
          final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(
            timestamp,
          );
          if (DateTime.now().difference(cacheTime) < cacheValidity) {
            return banner;
          }
        }
      }

      // Ambil dari API jika cache tidak ada atau sudah expired
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse('$prodUrl/merek/$slug'),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API mengembalikan banner dalam field banner
        final banner = data['banner'] as String?;

        if (banner != null) {
          // Simpan ke cache dan file lokal
          await prefs.setString('banner_$slug', banner);
          await prefs.setInt(
            'banner_${slug}_time',
            DateTime.now().millisecondsSinceEpoch,
          );

          final Map<String, dynamic> fileData = {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'banner': banner,
          };
          await file.writeAsString(jsonEncode(fileData));

          return banner;
        }
      } else {
        debugPrint('Error fetching banner for $slug: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in fetchBanner for $slug: $e');
    }

    return null;
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

  // Method untuk load data tipe yang dipanggil dari jelajah.dart
  Future<void> loadTypeData() async {
    try {
      // Load type counts dari cache dulu
      await _loadTypeCountsFromCache();

      // Jika tidak ada di cache atau sudah kadaluarsa, ambil dari API
      if ((filterOptions['brandCounts'] as Map<dynamic, dynamic>?)?.isEmpty ??
          true) {
        await _fetchTypeCountsFromApi();
      }
    } catch (e) {
      debugPrint('Error loading type data: $e');
    }
  }
}
