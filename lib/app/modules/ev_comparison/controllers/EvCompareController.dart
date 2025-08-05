import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infoev/app/services/app_token_service.dart'; // Tambahkan ini
import 'package:infoev/app/services/AppException.dart';

class EVComparisonController extends GetxController {
  var vehicleA = Rxn<VehicleModel>();
  var vehicleB = Rxn<VehicleModel>();

  var isLoadingA = false.obs;
  var isLoadingB = false.obs;
  var isCompared = false.obs;

  late final AppTokenService _appTokenService;

  String? _lastErrorMessageA;
  String? _lastErrorMessageB;

  bool _isShowingError = false; // Tambahkan flag

  // ────────────────────────────────────────────────────────────
  void selectVehicleA(String slug) => setVehicle(slug, true);
  void selectVehicleB(String slug) => setVehicle(slug, false);

  void compareNow() {
    if (vehicleA.value == null || vehicleB.value == null) {
      _showErrorOnce('Pilih dua kendaraan terlebih dahulu');
      return;
    }

    if (vehicleA.value!.id == vehicleB.value!.id) {
      _showErrorOnce('Tidak bisa membandingkan kendaraan yang sama');
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

  Future<List<Map<String, dynamic>>> searchVehiclesA(String query) async {
    isLoadingA.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKeySearchResults}A_${query.toLowerCase()}';
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getString('${cacheKey}_timestamp');
      if (cached != null && timestamp != null) {
        final cachedTime = DateTime.parse(timestamp);
        if (DateTime.now().difference(cachedTime) < cacheDuration) {
          _lastErrorMessageA = null;
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
        await _saveToCache(cacheKey, results);
        _lastErrorMessageA = null;
        return results;
      } else {
        final errorMsg = 'Gagal mencari kendaraan. Silakan coba lagi.';
        if (_lastErrorMessageA != errorMsg) {
          ErrorHandlerService.handleError(
            AppException(message: errorMsg, type: ErrorType.server),
            showToUser: true,
          );
          _lastErrorMessageA = errorMsg;
        }
        return [];
      }
    } catch (e) {
      final errorMsg = 'Terjadi masalah koneksi. Silakan cek internet Anda.';
      if (_lastErrorMessageA != errorMsg) {
        ErrorHandlerService.handleError(
          AppException(
            message: errorMsg,
            type: ErrorType.network,
            originalError: e,
          ),
          showToUser: true,
        );
        _lastErrorMessageA = errorMsg;
      }
      return [];
    } finally {
      isLoadingA.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> searchVehiclesB(String query) async {
    isLoadingB.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKeySearchResults}B_${query.toLowerCase()}';
      final cached = prefs.getString(cacheKey);
      final timestamp = prefs.getString('${cacheKey}_timestamp');
      if (cached != null && timestamp != null) {
        final cachedTime = DateTime.parse(timestamp);
        if (DateTime.now().difference(cachedTime) < cacheDuration) {
          _lastErrorMessageB = null;
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
        await _saveToCache(cacheKey, results);
        _lastErrorMessageB = null;
        return results;
      } else {
        final errorMsg = 'Gagal mencari kendaraan. Silakan coba lagi.';
        if (_lastErrorMessageB != errorMsg) {
          ErrorHandlerService.handleError(
            AppException(message: errorMsg, type: ErrorType.server),
            showToUser: true,
          );
          _lastErrorMessageB = errorMsg;
        }
        return [];
      }
    } catch (e) {
      final errorMsg = 'Terjadi masalah koneksi. Silakan cek internet Anda.';
      if (_lastErrorMessageB != errorMsg) {
        ErrorHandlerService.handleError(
          AppException(
            message: errorMsg,
            type: ErrorType.network,
            originalError: e,
          ),
          showToUser: true,
        );
        _lastErrorMessageB = errorMsg;
      }
      return [];
    } finally {
      isLoadingB.value = false;
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
    try {
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
        ErrorHandlerService.handleError(
          AppException(
            message: 'Gagal mengambil detail kendaraan. Silakan coba lagi.',
            type: ErrorType.server,
          ),
          showToUser: true,
        );
        throw Exception('Gagal mengambil detail kendaraan');
      }
    } catch (e) {
      ErrorHandlerService.handleError(
        e,
        showToUser: true,
      );
      throw Exception('Gagal mengambil detail kendaraan');
    }
  }

  void _showError(String message) {
    ErrorHandlerService.handleError(
      AppException(
        message: message,
        type: ErrorType.unknown,
      ),
      showToUser: true,
    );
  }

  void _showErrorOnce(String message) {
    if (_isShowingError) return;
    _isShowingError = true;
    ErrorHandlerService.handleError(
      AppException(
        message: message,
        type: ErrorType.unknown,
      ),
      showToUser: true,
    );
    // Reset flag setelah beberapa detik (misal, 2 detik)
    Future.delayed(const Duration(seconds: 2), () {
      _isShowingError = false;
    });
  }
}
