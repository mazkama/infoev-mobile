import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:infoev/app/widgets/login_alert_widget.dart';
import 'package:infoev/core/halper.dart';
import 'package:infoev/app/services/app_token_service.dart';
import 'package:infoev/core/local_db.dart';
import 'package:infoev/app/services/AppException.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infoev/core/ad_helper.dart';
import 'dart:math'; // Tambahkan di bagian import

class CalculatorController extends GetxController {
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  // Getter untuk status login
  bool get isLoggedIn => LocalDB.getToken() != null;

  // Tambahkan AppTokenService
  late final AppTokenService _appTokenService;

  // Vehicle search related
  final isSearching = false.obs;
  final isSearchLoading = false.obs;
  final hasSearched = false.obs;
  final searchResults = RxMap<String, List<dynamic>>({});
  final selectedVehicle = Rxn<Map<String, dynamic>>();

  // Input values
  final electricityPrice = 1445.0.obs; // Default PLN price per kWh
  final sliderValue = 1445.0.obs;
  final dailyDistance = 30.0.obs; // Default daily distance in km
  final dailyDistanceSlider = 30.0.obs;

  // Calculation results
  final costPerKm = 0.0.obs;
  final costPer100Km = 0.0.obs;
  final costPerMonth = 0.0.obs;
  final rangePerCharge = 0.0.obs;
  final batteryCapacity = 0.0.obs;
  final fullChargeCost = 0.0.obs;
  final dailyRunningCost = 0.0.obs;
  final monthlyRunningCost = 0.0.obs;

  // Constants for calculation
  double maintenanceCostPerKm =
      100.0; // Maintenance cost per km, will be updated based on vehicle type

  // For calculation
  double? consumption; // kWh/km
  double? batteryCapacityValue; // kWh
  double? maxRange; // km

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService();
    _loadRewardedAd();
    _loadInterstitialAd();
    checkLoginStatus();
  }

  @override
  void onClose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.onClose();
  }

  // Methods for search
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchResults.clear();
    }
  }

  void resetSearch() {
    isSearching.value = false;
    searchResults.clear();
    hasSearched.value = false;
  }

  // Metode untuk memeriksa status login
  void checkLoginStatus() {
    if (!isLoggedIn) {
      // Tutup halaman kalkulator jika belum login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Kembali ke halaman sebelumnya
        Get.back();
        
        // Tampilkan dialog login
        LoginAlertWidget.show(
          title: 'Masuk untuk Menggunakan Kalkulator',
          subtitle: 'Untuk mengakses kalkulator biaya, silakan login terlebih dahulu',
          icon: Icons.calculate_rounded,
        );
      });
    }
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      return;
    }
    hasSearched.value = true;

    try {
      isSearchLoading.value = true;
      final url = "$prodUrl/cari?q=$query";
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, List<dynamic>> formattedResults = {};
        if (data['vehicles'] != null && (data['vehicles'] as List).isNotEmpty) {
          formattedResults['KENDARAAN'] = List<dynamic>.from(data['vehicles']);
        }
        searchResults.value = formattedResults;
        hasError.value = false;
        errorMessage.value = '';
      } else {
        hasError.value = true;
        // Gunakan handler ramah
        ErrorHandlerService.handleError(
          AppException(
            message: 'Gagal melakukan pencarian. Silakan coba lagi.',
            type: ErrorType.server,
          ),
          showToUser: true,
        );
        errorMessage.value = 'Gagal melakukan pencarian. Silakan coba lagi.';
      }
    } catch (e) {
      hasError.value = true;
      // Gunakan handler ramah
      ErrorHandlerService.handleError(
        e,
        showToUser: true,
      );
      errorMessage.value = 'Terjadi kesalahan. Silakan cek koneksi internet Anda.';
    } finally {
      isSearchLoading.value = false;
    }
  }

  int _selectCount = 0;

  void selectVehicle(Map<String, dynamic> vehicle) {
    _selectCount++;
    if (_selectCount % 2 == 1) {
      // Ganjil: Random pilih Rewarded atau Interstitial
      final random = Random();
      final showRewarded = random.nextBool();

      if (showRewarded && _isRewardedAdReady && _rewardedAd != null) {
        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {},
        );
        _rewardedAd = null;
        _isRewardedAdReady = false;
        _loadRewardedAd();
      } else if (_isInterstitialAdReady && _interstitialAd != null) {
        _interstitialAd!.show();
        _interstitialAd = null;
        _isInterstitialAdReady = false;
        _loadInterstitialAd();
      } else if (_isRewardedAdReady && _rewardedAd != null) {
        // Jika random pilih interstitial tapi interstitial tidak ready, fallback ke rewarded
        _rewardedAd!.show(
          onUserEarnedReward: (ad, reward) {},
        );
        _rewardedAd = null;
        _isRewardedAdReady = false;
        _loadRewardedAd();
      }
      // Jika keduanya tidak ready, tidak tampilkan iklan
    }

    selectedVehicle.value = vehicle;
    isSearching.value = false;

    // Reset calculation values
    costPerKm.value = 0.0;
    costPer100Km.value = 0.0;
    costPerMonth.value = 0.0;

    // Set maintenance cost based on vehicle type_id if available in search results
    if (vehicle['type_id'] != null) {
      int typeId = cast<int>(vehicle['type_id'], 'type_id');
      String vehicleType = "";

      switch (typeId) {
        case 1:
          vehicleType = "mobil";
          maintenanceCostPerKm = 108.0;
          break;
        default:
          vehicleType = "lainnya";
          maintenanceCostPerKm = 42.0;
      }

      print(
        'DEBUG: Vehicle type_id from search: $typeId - Vehicle type: $vehicleType',
      );
      print('DEBUG: Maintenance cost set to: Rp $maintenanceCostPerKm per km');
    }

    fetchVehicleDetails(vehicle['slug']);
  }

  Future<void> fetchVehicleDetails(String slug) async {
    try {
      isLoading.value = true;
      final url = "$prodUrl/$slug";
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/json', 'x-app-key': appKey},
        ),
        platform: "android",
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        extractBatteryDetails(data);
        calculateCosts();
        hasError.value = false;
        errorMessage.value = '';
      } else {
        hasError.value = true;
        ErrorHandlerService.handleError(
          AppException(
            message: 'Gagal mendapatkan detail kendaraan. Silakan coba lagi.',
            type: ErrorType.server,
          ),
          showToUser: true,
        );
        errorMessage.value = 'Gagal mendapatkan detail kendaraan. Silakan coba lagi.';
      }
    } catch (e) {
      hasError.value = true;
      ErrorHandlerService.handleError(
        e,
        showToUser: true,
      );
      errorMessage.value = 'Terjadi kesalahan. Silakan cek koneksi internet Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  void extractBatteryDetails(Map<String, dynamic> data) {
    try {
      // Dapatkan specCategories dari data
      final List<dynamic> specCategories = data['specCategories'] ?? [];

      // Cari kategori Baterai
      final batteryCategory = specCategories.firstWhere(
        (category) => category['name'] == 'Baterai',
        orElse: () => null,
      );

      if (batteryCategory != null) {
        final specs = batteryCategory['specs'] as List<dynamic>;

        // Cari kapasitas baterai
        final capacitySpec = specs.firstWhere(
          (spec) => spec['name'] == 'Kapasitas',
          orElse: () => null,
        );

        if (capacitySpec != null &&
            capacitySpec['vehicles'] != null &&
            capacitySpec['vehicles'].isNotEmpty) {
          final vehicles = capacitySpec['vehicles'] as List<dynamic>;
          if (vehicles.isNotEmpty) {
            // Dapatkan nilai dari pivot
            final pivot = vehicles.first['pivot'];
            if (pivot != null && pivot['value'] != null) {
              batteryCapacityValue = cast<double>(pivot['value'], 'batteryCapacityValue');
              batteryCapacity.value = batteryCapacityValue ?? 0.0;
              print('Kapasitas Baterai: ${batteryCapacity.value} kWh');
            }
          }
        }

        // Skip konsumsi dari API, akan dihitung dari kapasitas dan jarak tempuh
        consumption =
            null; // Reset consumption so it will be calculated later from capacity/range

        // Cari jarak tempuh
        final rangeSpec = specs.firstWhere(
          (spec) => spec['name'] == 'Jarak Tempuh',
          orElse: () => null,
        );

        if (rangeSpec != null &&
            rangeSpec['vehicles'] != null &&
            rangeSpec['vehicles'].isNotEmpty) {
          final vehicles = rangeSpec['vehicles'] as List<dynamic>;
          if (vehicles.isNotEmpty) {
            final pivot = vehicles.first['pivot'];
            if (pivot != null && pivot['value'] != null) {
              maxRange = cast<double>(pivot['value'], 'maxRange');
              rangePerCharge.value = maxRange ?? 0.0;
              print('Jarak Tempuh: ${rangePerCharge.value} km');
            }
          }
        }
      }

      // Bisa juga ambil dari highlightSpecs jika ada
      final List<dynamic> highlightSpecs = data['highlightSpecs'] ?? [];

      // Cari kapasitas dari highlightSpecs jika belum ada
      if (batteryCapacityValue == null || batteryCapacityValue == 0.0) {
        final capacityHighlight = highlightSpecs.firstWhere(
          (spec) => spec['type'] == 'capacity',
          orElse: () => null,
        );

        if (capacityHighlight != null && capacityHighlight['value'] != null) {
          batteryCapacityValue = cast<double>(
            capacityHighlight['value'],
            'batteryCapacityValueHighlight',
          );
          batteryCapacity.value = batteryCapacityValue ?? 0.0;
          print(
            'Kapasitas Baterai (dari highlight): ${batteryCapacity.value} kWh',
          );
        }
      }

      // Cari jarak tempuh dari highlightSpecs jika belum ada
      if (maxRange == null || maxRange == 0.0) {
        final rangeHighlight = highlightSpecs.firstWhere(
          (spec) => spec['type'] == 'range',
          orElse: () => null,
        );

        if (rangeHighlight != null && rangeHighlight['value'] != null) {
          maxRange = cast<double>(rangeHighlight['value'], 'maxRangeHighlight');
          rangePerCharge.value = maxRange ?? 0.0;
          print('Jarak Tempuh (dari highlight): ${rangePerCharge.value} km');
        }
      }

      // Hitung konsumsi berdasarkan kapasitas dan jarak tempuh jika belum ada
      if ((consumption == null || consumption == 0.0) &&
          batteryCapacityValue != null &&
          batteryCapacityValue! > 0 &&
          maxRange != null &&
          maxRange! > 0) {
        consumption = batteryCapacityValue! / maxRange!;
        print('Konsumsi (dihitung): ${consumption} kWh/km');
      }
    } catch (e) {
      print('Error extracting battery details: $e');
    }
  }

  void calculateCosts() {
    if (consumption == null || batteryCapacityValue == null) {
      return;
    }

    print('Menghitung biaya dengan:');
    print('- Kapasitas baterai: ${batteryCapacityValue} kWh');
    print('- Konsumsi energi: ${consumption} kWh/km');
    print('- Jarak tempuh: ${maxRange} km');
    print('- Harga listrik: ${electricityPrice.value} Rp/kWh');
    print('- Biaya perawatan: Rp $maintenanceCostPerKm per km');

    // Pastikan konsumsi dalam kWh/km
    double consumptionToUse = consumption!;

    // Calculate cost per km
    // Rumus: Electricity Cost per km = Consumption (kWh/km) × Electricity Price (IDR/kWh)
    final costPerKmValue = consumptionToUse * electricityPrice.value;
    costPerKm.value = costPerKmValue;
    print('Biaya per km: Rp ${costPerKmValue.toStringAsFixed(2)}');

    // Calculate cost per 100km
    costPer100Km.value = costPerKmValue * 100;
    print('Biaya per 100km: Rp ${costPer100Km.value.toStringAsFixed(2)}');

    // Calculate full charge cost
    // Rumus: Full Charge Cost = Battery Capacity (kWh) × Electricity Price (IDR/kWh)
    fullChargeCost.value = batteryCapacityValue! * electricityPrice.value;
    print(
      'Biaya pengisian penuh: Rp ${fullChargeCost.value.toStringAsFixed(2)}',
    );

    // Calculate daily running cost
    // Rumus: Total Daily Running Cost = Average Daily Distance (km) × (Electricity Cost per km + Maintenance Cost per km)
    final totalCostPerKm = costPerKmValue + maintenanceCostPerKm;
    dailyRunningCost.value = dailyDistance.value * totalCostPerKm;
    print('Biaya harian: Rp ${dailyRunningCost.value.toStringAsFixed(2)}');

    // Calculate monthly running cost
    // Rumus: Total Monthly Running Cost = Total Daily Running Cost × 30
    monthlyRunningCost.value = dailyRunningCost.value * 30;
    costPerMonth.value = dailyDistance.value * totalCostPerKm * 30;
    print('Biaya bulanan: Rp ${costPerMonth.value.toStringAsFixed(2)}');
  }

  void updateElectricityPrice(double price) {
    electricityPrice.value = price;
    sliderValue.value = price;
    calculateCosts();
  }

  void updateDailyDistance(double distance) {
    dailyDistance.value = distance;
    dailyDistanceSlider.value = distance;
    calculateCosts();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId(isTest: false),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId(isTest: false),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  T cast<T>(dynamic value, String fieldName) {
  if (value == null) return null as T;

  // Handle int dan int? dari String/int
  if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString())) &&
      (value is String || value is int)) {
    if (value is int) return value as T;
    final intValue = int.tryParse(value.toString());
    if (intValue != null) return intValue as T;
    if (T.toString().contains('?')) return null as T;
  }

  // Handle double dan double? dari String/double/int
  if ((T == double || RegExp(r'^double(\?|)$').hasMatch(T.toString())) &&
      (value is String || value is double || value is int)) {
    if (value is double) return value as T;
    if (value is int) return value.toDouble() as T;
    final doubleValue = double.tryParse(value.toString());
    if (doubleValue != null) return doubleValue as T;
    if (T.toString().contains('?')) return null as T;
  }

  // Handle String dan String? dari int/double/String
  if ((T == String || RegExp(r'^String(\?|)$').hasMatch(T.toString())) &&
      (value is int || value is double || value is String)) {
    return value.toString() as T;
  }

  if (value is T) return value;

  // print('Warning: field "$fieldName" expected $T but got ${value.runtimeType}');
  return value as T;
}
}