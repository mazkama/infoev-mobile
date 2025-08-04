import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infoev/app/services/app_token_service.dart'; // Tambahkan ini

class EVComparisonController extends GetxController {
  var vehicleA = Rxn<VehicleModel>();
  var vehicleB = Rxn<VehicleModel>();

  var isLoadingA = false.obs;
  var isLoadingB = false.obs;
  var isSearching = false.obs;
  var isCompared = false.obs;

  late final AppTokenService _appTokenService; // Tambahkan ini

  // ────────────────────────────────────────────────────────────
  void selectVehicleA(String slug) => setVehicle(slug, true);
  void selectVehicleB(String slug) => setVehicle(slug, false);

  void compareNow() {
    if (vehicleA.value == null || vehicleB.value == null) {
      _showError('Pilih dua kendaraan terlebih dahulu');
      return;
    }

    if (vehicleA.value!.id == vehicleB.value!.id) {
      _showError('Tidak bisa membandingkan kendaraan yang sama');
      return;
    }

    isCompared.value = true;
  }

  void resetComparison() {
    vehicleA.value = null;
    vehicleB.value = null;
    isCompared.value = false;
  }

  static const cacheDuration = Duration(hours: 12);
  static const String _cacheKeyVehicleDetails = 'cache_vehicle_details_';
  static const String _cacheKeySearchResults = 'cache_vehicle_search_';

  @override
  void onInit() async {
    super.onInit(); 
    _appTokenService = AppTokenService();
    await _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    if (vehicleA.value != null) {
      _loadCachedVehicle(prefs, vehicleA.value!.slug, true);
    }
    if (vehicleB.value != null) {
      _loadCachedVehicle(prefs, vehicleB.value!.slug, false);
    }
  }

  Future<void> _loadCachedVehicle(
    SharedPreferences prefs,
    String slug,
    bool isFirst,
  ) async {
    final cached = prefs.getString('${_cacheKeyVehicleDetails}$slug');
    final timestamp = prefs.getString(
      '${_cacheKeyVehicleDetails}${slug}_timestamp',
    );

    if (cached != null && timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cachedTime) < cacheDuration) {
        final data = json.decode(cached);
        final vehicle = VehicleModel.fromJson(data);
        if (isFirst) {
          vehicleA.value = vehicle;
        } else {
          vehicleB.value = vehicle;
        }
      }
    }
  }

  Future<void> _saveToCache(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }

  Future<void> setVehicle(String slug, bool isFirst) async {
    if (isFirst) {
      isLoadingA.value = true;
    } else {
      isLoadingB.value = true;
    }

    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_cacheKeyVehicleDetails}$slug');
      final timestamp = prefs.getString(
        '${_cacheKeyVehicleDetails}${slug}_timestamp',
      );

      if (cached != null && timestamp != null) {
        final cachedTime = DateTime.parse(timestamp);
        if (DateTime.now().difference(cachedTime) < cacheDuration) {
          final data = json.decode(cached);
          final vehicle = VehicleModel.fromJson(data);
          if (isFirst) {
            vehicleA.value = vehicle;
          } else {
            vehicleB.value = vehicle;
          }
          return;
        }
      }

      final data = await _fetchVehicleDetail(slug);
      final vehicle = VehicleModel.fromJson(data);

      // Save to cache
      await _saveToCache('${_cacheKeyVehicleDetails}$slug', data);

      if (isFirst) {
        vehicleA.value = vehicle;
      } else {
        vehicleB.value = vehicle;
      }
    } catch (e) {
      _showError('Tidak bisa memuat detail kendaraan: $e');
    } finally {
      if (isFirst) {
        isLoadingA.value = false;
      } else {
        isLoadingB.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>> searchVehicles(String query) async {
    isSearching.value = true;

    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKeySearchResults}${query.toLowerCase()}';
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getString('${cacheKey}_timestamp');

      if (cached != null && timestamp != null) {
        final cachedTime = DateTime.parse(timestamp);
        if (DateTime.now().difference(cachedTime) < cacheDuration) {
          return List<Map<String, dynamic>>.from(json.decode(cached));
        }
      }

      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse('$prodUrl/cari?q=$encodedQuery');
      final res = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          url,
          headers: {'x-app-key': appKey},
        ),
        platform: "android",
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final results = List<Map<String, dynamic>>.from(body['vehicles']);

        // Save to cache
        await _saveToCache(cacheKey, results);

        return results;
      } else {
        throw Exception('Gagal mencari kendaraan');
      }
    } catch (e) {
      _showError('Gagal mencari kendaraan: $e');
      return [];
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_cacheKeyVehicleDetails) ||
          key.startsWith(_cacheKeySearchResults)) {
        await prefs.remove(key);
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchVehicleDetail(String slug) async {
    final url = Uri.parse('$prodUrl/$slug');
    final res = await _appTokenService.requestWithAutoRefresh(
      requestFn: (appKey) => http.get(
        url,
        headers: {'x-app-key': appKey, 'Accept': 'application/json'},
      ),
      platform: "android",
    );
    
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      debugPrint('Fetched vehicle detail for $slug: ${data.keys}');
      return data;
    } else {
      debugPrint('Error fetching vehicle: ${res.statusCode}, ${res.body}');
      throw Exception('Gagal mengambil detail kendaraan');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Gagal',
      message,
      backgroundColor: Colors.red[400],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}
