import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/BrandDetailModel.dart';
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/modules/explore/model/VehicleTipeModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infoev/app/services/app_token_service.dart';

class BrandDetailController extends GetxController { 

  // Data state
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = "".obs;

  // Cache keys
  final String redisCacheKey = "vehicle_cache_";
  final String filterCacheKey = "brand_detail_filter_";

  // Cache expiration (24 jam dalam milidetik)
  final int cacheExpiration = 24 * 60 * 60 * 1000;

  // Brand data
  var brandDetail = Rxn<BrandDetailModel>();
  var vehicleTypes = <VehicleTypeModel>[].obs;

  // Filter and sorting state
  var searchQuery = "".obs;
  var isSearching = false.obs;
  var filterByTypeId = 0.obs;
  var filteredVehicles = <VehicleModel>[].obs;
  var sortBy = "name".obs;
  var sortOrder = "asc".obs;

  // Add AppTokenService
  late final AppTokenService _appTokenService;

  // List of endpoints
  final Map<String, String> typeEndpoints = {
    'mobil': '$baseUrlDev/tipe/mobil',
    'sepeda-motor': '$baseUrlDev/tipe/sepeda-motor',
    'sepeda': '$baseUrlDev/tipe/sepeda',
    'skuter': '$baseUrlDev/tipe/skuter',
  };

  // Mendapatkan kisaran harga kendaraan berdasarkan slug
  var vehiclePriceRanges = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService();
    fetchVehicleTypes();
  }

  // Helper method to get headers with app_key
  Future<Map<String, String>> _getAuthHeaders() async {
    final appKey = await _appTokenService.getAppKey();
    if (appKey == null) {
      throw Exception('Failed to get app_key');
    }
    return {
      'Accept': 'application/json',
      'x-app-key': appKey,
    };
  }

  // Memuat detail merek berdasarkan brand ID
  Future<void> fetchBrandDetail(int brandId) async {
    String cacheKey = "${redisCacheKey}brand_$brandId";
    isLoading.value = true;
    hasError.value = false;

    try {
      List<VehicleModel> allVehicles = [];
      bool dataFromCache = false;
      String? brandSlug;

      // First, get the brand slug from cache
      final prefs = await SharedPreferences.getInstance();
      final slugCache = prefs.getString('brand_slug_$brandId');

      if (slugCache != null) {
        brandSlug = slugCache;
      } else {
        // If not in cache, get from API with app_key
        try {
          final headers = await _getAuthHeaders();
          final response = await http.get(
            Uri.parse("$baseUrlDev/merek"), 
            headers: headers
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List<dynamic> items = data['items'] ?? [];
            final brandItem = items
                .cast<Map<String, dynamic>>()
                .firstWhereOrNull((item) => item['id'] == brandId);
            if (brandItem != null) {
              brandSlug = brandItem['slug'] as String;
              // Cache the slug
              await prefs.setString('brand_slug_$brandId', brandSlug);
            }
          }
        } catch (e) {
          debugPrint('Error getting brand slug: $e');
        }
      }

      if (brandSlug == null) {
        hasError.value = true;
        errorMessage.value = "Could not find brand";
        isLoading.value = false;
        return;
      }

      // Check complete cache first (includes vehicles and brand info)
      try {
        final cacheData = prefs.getString(cacheKey);
        final cacheTimestamp = prefs.getInt("${cacheKey}_timestamp") ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        if (cacheData != null &&
            (currentTime - cacheTimestamp < cacheExpiration)) {
          debugPrint('Loading complete data from cache for brand ID: $brandId');
          final cachedData = jsonDecode(cacheData);

          // Load vehicles from cache
          allVehicles = VehicleModel.fromJsonList(cachedData['vehicles']);

          // Load brand details from cache
          brandDetail.value = BrandDetailModel(
            vehicles: allVehicles,
            nameBrand: cachedData['name_brand'] ?? '',
            banner: cachedData['banner'] ?? '',
            brandId: brandId,
          );

          dataFromCache = true;

          // Load year cache from SharedPreferences
          await _loadYearCacheFromPrefs(brandId);

          // Load vehicle years before applying filters
          await _loadVehicleYears(allVehicles);
          applyFilters();

          // Refresh in background after delay
          Future.delayed(const Duration(milliseconds: 500), () {
            _refreshInBackground(brandId, brandSlug!);
          });

          return;
        }
      } catch (e) {
        debugPrint('Cache error: $e');
      }

      // If no cache or expired, fetch fresh data
      if (!dataFromCache) {
        await _fetchFreshData(brandId, brandSlug);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = "Error: ${e.toString()}";
      debugPrint('Error in fetchBrandDetail: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to fetch fresh data
  Future<void> _fetchFreshData(int brandId, String brandSlug) async {
    debugPrint('Fetching fresh data for brand ID: $brandId');
    List<VehicleModel> allVehicles = [];
    final headers = await _getAuthHeaders();

    // Fetch vehicles from all endpoints
    for (var endpoint in typeEndpoints.values) {
      try {
        final response = await http.get(
          Uri.parse(endpoint),
          headers: headers
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final vehicles =
              (data['vehicles'] as List)
                  .where((v) => v['brand_id'] == brandId)
                  .toList();
          allVehicles.addAll(VehicleModel.fromJsonList(vehicles));
        }
      } catch (e) {
        debugPrint('Error fetching from endpoint: $e');
      }
    }

    // Get brand details
    try {
      final brandResponse = await http.get(
        Uri.parse("$baseUrlDev/merek/$brandSlug"),
        headers: headers,
      );
      if (brandResponse.statusCode == 200) {
        final brandData = jsonDecode(brandResponse.body);

        // Update brandDetail
        brandDetail.value = BrandDetailModel(
          vehicles: allVehicles,
          nameBrand: brandData['name_brand'] ?? '',
          banner: brandData['banner'] ?? '',
          brandId: brandId,
        );

        // Load vehicle years from API before applying filters
        await _loadVehicleYears(allVehicles);

        // Save year cache to SharedPreferences
        await _saveYearCacheToPrefs(brandId);

        // Save complete data to cache
        await _saveToCache(brandId, allVehicles, brandData);
        applyFilters();
      } else {
        throw Exception(
          "Error fetching brand details: ${brandResponse.statusCode}",
        );
      }
    } catch (e) {
      debugPrint('Error fetching brand details: $e');
      throw e;
    }
  }

  // Helper method to refresh data in background
  Future<void> _refreshInBackground(int brandId, String brandSlug) async {
    try {
      await _fetchFreshData(brandId, brandSlug);
    } catch (e) {
      debugPrint('Background refresh error: $e');
    }
  }

  // Helper method to save data to cache
  Future<void> _saveToCache(
    int brandId,
    List<VehicleModel> vehicles,
    Map<String, dynamic> brandData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = "${redisCacheKey}brand_$brandId";

      final cacheData = {
        'vehicles': vehicles.map((v) => v.toJson()).toList(),
        'name_brand': brandData['name_brand'],
        'banner': brandData['banner'],
        'brand_id': brandId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      await prefs.setInt(
        "${cacheKey}_timestamp",
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  // Memuat tipe kendaraan
  Future<void> fetchVehicleTypes() async {
    try {
      // Cek cache terlebih dahulu
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString("vehicle_types_cache");
      final cacheTimestamp = prefs.getInt("vehicle_types_cache_timestamp") ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Jika data cache masih valid
      if (cacheData != null &&
          (currentTime - cacheTimestamp < cacheExpiration)) {
        final data = jsonDecode(cacheData);
        vehicleTypes.value = VehicleTypeModel.fromJsonList(data['items']);
        return;
      }

      // Jika tidak ada cache atau cache tidak valid, fetch dari API dengan app_key
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrlDev/tipe"),
        headers: headers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        vehicleTypes.value = VehicleTypeModel.fromJsonList(data['items']);

        // Simpan ke cache
        await prefs.setString("vehicle_types_cache", response.body);
        await prefs.setInt("vehicle_types_cache_timestamp", currentTime);
      } else {
        debugPrint(
          "Error fetching vehicle types: API returned status ${response.statusCode}",
        );
        // Gunakan data default jika ada error
        vehicleTypes.value = _getDefaultVehicleTypes();
      }
    } catch (e) {
      debugPrint("Error fetching vehicle types: ${e.toString()}");
      // Gunakan data default jika ada error
      vehicleTypes.value = _getDefaultVehicleTypes();
    }
  }

  // Data default jika tidak bisa mengambil dari API
  List<VehicleTypeModel> _getDefaultVehicleTypes() {
    final jsonStr = '''
    {
      "items": [
        {
          "id": 1,
          "name": "Mobil",
          "slug": "mobil",
          "created_at": "2023-01-04T08:50:08.000000Z",
          "updated_at": "2023-01-04T08:50:08.000000Z",
          "vehicles_count": 90
        },
        {
          "id": 3,
          "name": "Sepeda",
          "slug": "sepeda",
          "created_at": "2023-01-04T08:50:22.000000Z",
          "updated_at": "2023-01-04T08:50:22.000000Z",
          "vehicles_count": 40
        },
        {
          "id": 2,
          "name": "Sepeda Motor",
          "slug": "sepeda-motor",
          "created_at": "2023-01-04T08:50:16.000000Z",
          "updated_at": "2023-01-04T08:50:16.000000Z",
          "vehicles_count": 112
        },
        {
          "id": 5,
          "name": "Skuter",
          "slug": "skuter",
          "created_at": "2023-01-04T08:50:35.000000Z",
          "updated_at": "2023-01-04T08:50:35.000000Z",
          "vehicles_count": 13
        }
      ]
    }
    ''';

    final data = jsonDecode(jsonStr);
    return VehicleTypeModel.fromJsonList(data['items']);
  }

  // Mendapatkan nama tipe berdasarkan ID
  String getTypeName(int typeId) {
    final type = vehicleTypes.firstWhereOrNull((type) => type.id == typeId);
    return type?.name ?? 'Tidak diketahui';
  }

  // Mendapatkan tahun kendaraan berdasarkan VehicleModel
  String getVehicleYear(VehicleModel vehicle) {
    // Check cache first (same pattern as getTypeName)
    if (_vehicleYearCache.containsKey(vehicle.slug)) {
      return _vehicleYearCache[vehicle.slug]!;
    }

    // Method 1: Try from spec.value (current approach)
    if (vehicle.spec?.value != null && vehicle.spec!.value.isNotEmpty) {
      final year = vehicle.spec!.value.split('.').first;
      if (RegExp(r'^\d{4}$').hasMatch(year)) {
        return year;
      }
    }

    // Method 2: Try to get year from vehicle name if it contains 4 digits
    final nameYearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(vehicle.name);
    if (nameYearMatch != null) {
      return nameYearMatch.group(1) ?? '';
    }

    // Method 3: Extract year from slug if it contains year pattern
    final slugYearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(vehicle.slug);
    if (slugYearMatch != null) {
      return slugYearMatch.group(1) ?? '';
    }

    return '';
  }

  // Cache untuk menyimpan data tahun kendaraan
  final Map<String, String> _vehicleYearCache = {};

  // Mendapatkan tahun kendaraan dengan mengakses API detail kendaraan (optimized concurrent loading)
  Future<void> _loadVehicleYears(List<VehicleModel> vehicles) async {
    // Filter vehicles that are not in cache
    final vehiclesToLoad =
        vehicles
            .where((vehicle) => !_vehicleYearCache.containsKey(vehicle.slug))
            .toList();

    if (vehiclesToLoad.isEmpty) {
      debugPrint('All vehicle years already in cache');
      return;
    }

    debugPrint('Loading years for ${vehiclesToLoad.length} vehicles');

    // Process vehicles in batches of 6 concurrent requests to avoid overwhelming the server
    const batchSize = 6;
    for (int i = 0; i < vehiclesToLoad.length; i += batchSize) {
      final batch = vehiclesToLoad.skip(i).take(batchSize).toList();

      // Create concurrent futures for this batch
      final futures =
          batch.map((vehicle) => _loadSingleVehicleYear(vehicle)).toList();

      // Wait for all requests in this batch to complete
      await Future.wait(futures);

      debugPrint(
        'Completed batch ${(i / batchSize).floor() + 1}/${((vehiclesToLoad.length - 1) / batchSize).floor() + 1}',
      );
    }

    debugPrint('Finished loading all vehicle years');
  }

  // Helper method to load year for a single vehicle
  Future<void> _loadSingleVehicleYear(VehicleModel vehicle) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrlDev/${vehicle.slug}'),
        headers: headers
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final specCategories = data['specCategories'] as List<dynamic>?;

        if (specCategories != null) {
          for (var category in specCategories) {
            final specs = category['specs'] as List<dynamic>?;
            if (specs != null) {
              for (var spec in specs) {
                final specName = spec['name'] as String?;
                if (specName != null &&
                    specName.toLowerCase().contains('tahun')) {
                  final specVehicles = spec['vehicles'] as List<dynamic>?;
                  if (specVehicles != null) {
                    for (var specVehicle in specVehicles) {
                      if (specVehicle['id'] == vehicle.id) {
                        final pivot = specVehicle['pivot'];
                        if (pivot != null && pivot['value'] != null) {
                          final value = pivot['value'].toString();
                          final extractedYear = value.split('.').first;
                          if (RegExp(r'^\d{4}$').hasMatch(extractedYear)) {
                            _vehicleYearCache[vehicle.slug] = extractedYear;
                            return; // Exit early when year is found
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading year for ${vehicle.slug}: $e');
    }

    // Jika tidak ditemukan, cache sebagai string kosong
    if (!_vehicleYearCache.containsKey(vehicle.slug)) {
      _vehicleYearCache[vehicle.slug] = '';
    }
  }

  // Load year cache from SharedPreferences
  Future<void> _loadYearCacheFromPrefs(int brandId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final yearCacheKey = "${redisCacheKey}years_$brandId";
      final cacheData = prefs.getString(yearCacheKey);
      final cacheTimestamp = prefs.getInt("${yearCacheKey}_timestamp") ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cacheData != null &&
          (currentTime - cacheTimestamp < cacheExpiration)) {
        final Map<String, dynamic> cachedYears = jsonDecode(cacheData);
        _vehicleYearCache.addAll(cachedYears.cast<String, String>());
        debugPrint(
          'Loaded ${_vehicleYearCache.length} vehicle years from cache',
        );
      }
    } catch (e) {
      debugPrint('Error loading year cache: $e');
    }
  }

  // Save year cache to SharedPreferences
  Future<void> _saveYearCacheToPrefs(int brandId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final yearCacheKey = "${redisCacheKey}years_$brandId";

      await prefs.setString(yearCacheKey, jsonEncode(_vehicleYearCache));
      await prefs.setInt(
        "${yearCacheKey}_timestamp",
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('Saved ${_vehicleYearCache.length} vehicle years to cache');
    } catch (e) {
      debugPrint('Error saving year cache: $e');
    }
  }

  // Menerapkan filter dan sort pada kendaraan
  void applyFilters() {
    if (brandDetail.value == null) return;

    var result = List<VehicleModel>.from(brandDetail.value!.vehicles);

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      result =
          result
              .where(
                (vehicle) => vehicle.name.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
              )
              .toList();
    }

    // Filter by type
    if (filterByTypeId.value > 0) {
      result =
          result
              .where((vehicle) => vehicle.typeId == filterByTypeId.value)
              .toList();
    }

    // Always sort by name in ascending order first
    result.sort((a, b) => a.name.compareTo(b.name));

    // Then apply user's sort preference
    if (sortBy.value != 'name' || sortOrder.value != 'asc') {
      result.sort((a, b) {
        int comparison;

        if (sortBy.value == 'year') {
          final yearA = a.spec?.value ?? '0';
          final yearB = b.spec?.value ?? '0';
          comparison = yearA.compareTo(yearB);
        } else {
          comparison = a.name.compareTo(b.name);
        }

        return sortOrder.value == 'asc' ? comparison : -comparison;
      });
    }

    filteredVehicles.value = result;
    saveFilterSettings();
  }

  // Mencari kendaraan
  void searchVehicles(String query) {
    searchQuery.value = query;

    // Jangan panggil langsung applyFilters() agar tidak menghilangkan filter tipe
    if (brandDetail.value == null) return;

    var result = List<VehicleModel>.from(brandDetail.value!.vehicles);

    // Filter by search query
    if (query.isNotEmpty) {
      result =
          result
              .where(
                (vehicle) =>
                    vehicle.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    }

    // Filter by type (tetap pertahankan filter tipe yang sudah dipilih)
    if (filterByTypeId.value > 0) {
      result =
          result
              .where((vehicle) => vehicle.typeId == filterByTypeId.value)
              .toList();
    }

    // Terapkan pengurutan yang sama seperti sebelumnya
    result.sort((a, b) {
      int comparison;

      if (sortBy.value == 'year') {
        // Use the helper method to extract years consistently
        final yearA = getVehicleYear(a);
        final yearB = getVehicleYear(b);

        final yearIntA = int.tryParse(yearA) ?? 0;
        final yearIntB = int.tryParse(yearB) ?? 0;
        comparison = yearIntA.compareTo(yearIntB);
      } else {
        comparison = a.name.compareTo(b.name);
      }

      return sortOrder.value == 'asc' ? comparison : -comparison;
    });

    filteredVehicles.value = result;
    saveFilterSettings();
  }

  // Toggle search mode
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchQuery.value = "";
      applyFilters();
    }
  }

  // Mengatur filter berdasarkan tipe
  Future<void> filterByType(int typeId) async {
    filterByTypeId.value = typeId;

    if (brandDetail.value != null) {
      if (typeId == 0) {
        // Show all vehicles, sorted by slug
        filteredVehicles.value = List<VehicleModel>.from(
          brandDetail.value!.vehicles,
        )..sort((a, b) => a.slug.compareTo(b.slug));
      } else {
        // Filter by type and sort by slug
        filteredVehicles.value =
            brandDetail.value!.vehicles
                .where((v) => v.typeId == typeId)
                .toList()
              ..sort((a, b) => a.slug.compareTo(b.slug));
      }
    }

    await saveFilterSettings();
  }

  // Mengatur sort
  void sortVehicles(String by, String order) {
    sortBy.value = by;
    sortOrder.value = order;

    if (filteredVehicles.isEmpty) return;

    filteredVehicles.sort((a, b) {
      int comparison;

      switch (by) {
        case 'name':
          comparison = a.slug.compareTo(
            b.slug,
          ); // Changed from name to slug for consistent sorting
          break;
        case 'year':
          // Use the helper method to extract years consistently
          final yearA = getVehicleYear(a);
          final yearB = getVehicleYear(b);

          final yearIntA = int.tryParse(yearA) ?? 0;
          final yearIntB = int.tryParse(yearB) ?? 0;
          comparison = yearIntA.compareTo(yearIntB);
          // If years are equal, sort by slug for consistency
          if (comparison == 0) {
            comparison = a.slug.compareTo(b.slug);
          }
          break;
        default:
          comparison = a.slug.compareTo(b.slug);
      }

      return order == 'asc' ? comparison : -comparison;
    });

    saveFilterSettings();
  }

  // Reset semua filter
  void resetFilters() {
    searchQuery.value = "";
    isSearching.value = false;
    filterByTypeId.value = 0;
    sortBy.value = "name";
    sortOrder.value = "asc";
    applyFilters();
    saveFilterSettings();
  }

  // Menyimpan pengaturan filter ke cache
  Future<void> saveFilterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final slug = Get.parameters['slug'];

      if (slug == null) return;

      final filterSettings = {
        'searchQuery': searchQuery.value,
        'filterByTypeId': filterByTypeId.value,
        'sortBy': sortBy.value,
        'sortOrder': sortOrder.value,
      };

      await prefs.setString('$filterCacheKey$slug', jsonEncode(filterSettings));
    } catch (e) {
      debugPrint("Error saving filter settings: ${e.toString()}");
    }
  }

  // Memuat pengaturan filter dari cache
  Future<void> loadFilterSettings() async {
    try {
      // Reset filterByTypeId ke 0 (Semua) saat memuat ulang halaman
      filterByTypeId.value = 0;

      final prefs = await SharedPreferences.getInstance();
      final slug = Get.parameters['slug'];

      if (slug == null) return;

      final filterData = prefs.getString('$filterCacheKey$slug');

      if (filterData != null) {
        final settings = jsonDecode(filterData);

        searchQuery.value = settings['searchQuery'] ?? "";
        isSearching.value = searchQuery.value.isNotEmpty;
        // Tidak menggunakan filterByTypeId dari cache, selalu gunakan 0 (Semua)
        sortBy.value = settings['sortBy'] ?? "name";
        sortOrder.value = settings['sortOrder'] ?? "asc";
      }

      // Selalu terapkan filter setelah memuat pengaturan
      applyFilters();
    } catch (e) {
      debugPrint("Error loading filter settings: ${e.toString()}");
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    final brandIdStr = Get.parameters['brandId'];
    if (brandIdStr != null) {
      final brandId = int.tryParse(brandIdStr);
      if (brandId != null) {
        // Hapus cache untuk memaksa load baru
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove("${redisCacheKey}brand_$brandId");
        await prefs.remove("${redisCacheKey}brand_${brandId}_timestamp");

        // Clear current data and reload
        hasError.value = false;
        errorMessage.value = "";

        await fetchBrandDetail(brandId);
      }
    }
  }

  // Mendapatkan slug tipe berdasarkan ID
  String? getTypeSlug(int typeId) {
    final type = vehicleTypes.firstWhereOrNull((type) => type.id == typeId);
    return type?.slug;
  }

  // Mendapatkan kendaraan berdasarkan tipe spesifik
  Future<void> fetchVehiclesByType(String typeSlug) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse("$baseUrlDev/tipe/$typeSlug"),
        headers: headers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> vehiclesJson = data['vehicles'] ?? [];

        // Filter hanya kendaraan dari merek yang sedang dilihat
        if (brandDetail.value != null) {
          final brandId = brandDetail.value!.brandId;
          final brandSlug = brandDetail.value!.nameBrand.toLowerCase();

          // Konversi semua kendaraan ke VehicleModel
          final allVehiclesOfType = VehicleModel.fromJsonList(vehiclesJson);

          // Filter berdasarkan brand_id agar hanya menampilkan kendaraan dari merek yang sedang dilihat
          final filteredByBrand =
              allVehiclesOfType.where((vehicle) {
                return vehicle.brandId == brandId;
              }).toList();

          // Update filtered vehicles
          filteredVehicles.value = filteredByBrand;

          debugPrint(
            "Found ${filteredVehicles.length} vehicles of type $typeSlug for brand $brandSlug",
          );
        } else {
          // Jika tidak ada brand detail, gunakan filter biasa
          applyFilters();
        }
      } else {
        debugPrint("Error fetching vehicles by type: ${response.statusCode}");
        // Jika gagal, gunakan filter dari data yang sudah ada
        applyFilters();
      }
    } catch (e) {
      debugPrint("Error fetching vehicles by type: ${e.toString()}");
      // Jika ada error, gunakan filter dari data yang sudah ada
      applyFilters();
    }
  }

  // Pre-cache semua harga kendaraan yang ditampilkan
  void precacheVehiclePrices(List<String> slugs) {
    // Generate harga statis untuk semua slug
    for (var slug in slugs) {
      if (!vehiclePriceRanges.containsKey(slug)) {
        final int multiplier = slug.length * 100000;
        final int basePrice = 15000000 + multiplier;

        final formatted = basePrice
            .toStringAsFixed(0)
            .replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (match) => '${match[1]}.',
            );

        vehiclePriceRanges[slug] = 'Rp $formatted';
      }
    }
  }

  String getVehiclePriceRange(String slug) {
    // Hanya kembalikan harga yang sudah di-cache tanpa mengubah state
    return vehiclePriceRanges[slug] ?? '';
  }

  // Kode asli api ditangguhkan
  /*
  Future<void> _fetchVehiclePriceRange(String slug) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/$slug'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cek apakah ada highlightSpecs dengan type price
        if (data['highlightSpecs'] != null) {
          final List<dynamic> highlightSpecs = data['highlightSpecs'];
          for (var spec in highlightSpecs) {
            if (spec['type'] == 'price') {
              final value = spec['value']?.toString();
              final unit = spec['unit'] as String?;
              if (value != null && value.isNotEmpty) {
                // Format harga secara proper
                try {
                  final price = double.parse(value);
                  final formatted = price.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (match) => '${match[1]}.',
                  );
                  vehiclePriceRanges[slug] = '${unit ?? 'Rp'} $formatted';
                  return;
                } catch (e) {
                  vehiclePriceRanges[slug] = '${unit ?? 'Rp'} $value';
                  return;
                }
              }
            }
          }
        }
        
        // Jika tidak ada di highlightSpecs, cari di specCategories
        final specCategories = data['specCategories'];
        if (specCategories != null) {
          for (var category in specCategories) {
            final categoryName = category['name'].toString().toLowerCase();
            if (categoryName.contains('harga')) {
              final specs = category['specs'];
              if (specs != null && specs is List && specs.isNotEmpty) {
                for (var spec in specs) {
                  // Periksa apakah ada data kendaraan
                  if (spec['vehicles'] != null && (spec['vehicles'] as List).isNotEmpty) {
                    final vehicle = spec['vehicles'][0];
                    if (vehicle['pivot'] != null) {
                      final pivot = vehicle['pivot'];
                      final value = pivot['value']?.toString();
                      
                      if (value != null && value.isNotEmpty) {
                        final unit = spec['unit'] as String?;
                        // Format harga secara proper
                        try {
                          final price = double.parse(value);
                          final formatted = price.toStringAsFixed(0).replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (match) => '${match[1]}.',
                          );
                          vehiclePriceRanges[slug] = '${unit ?? 'Rp'} $formatted';
                          return;
                        } catch (e) {
                          vehiclePriceRanges[slug] = '${unit ?? 'Rp'} $value';
                          return;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching price range: $e');
    }
  }
  */
}
