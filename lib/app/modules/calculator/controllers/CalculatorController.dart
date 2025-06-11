import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:infoev/app/widgets/login_alert_widget.dart';
import 'package:infoev/core/halper.dart';
import 'package:infoev/app/services/app_token_service.dart';
import 'package:infoev/core/local_db.dart';

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

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService();
    // Cek login status saat controller diinisialisasi
    checkLoginStatus();
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

      // Ambil app_key dari service
      final appKey = await _appTokenService.getAppKey();
      if (appKey == null) {
        hasError.value = true;
        errorMessage.value = 'Gagal mendapatkan app_key';
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrlDev/cari?q=$query'),
        headers: {'Accept': 'application/json', 'x-app-key': appKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final Map<String, List<dynamic>> formattedResults = {};

        if (data['vehicles'] != null && (data['vehicles'] as List).isNotEmpty) {
          formattedResults['KENDARAAN'] = List<dynamic>.from(data['vehicles']);
        }

        searchResults.value = formattedResults;
      } else {
        hasError.value = true;
        errorMessage.value = 'Gagal melakukan pencarian';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Terjadi kesalahan: $e';
    } finally {
      isSearchLoading.value = false;
    }
  }

  void selectVehicle(Map<String, dynamic> vehicle) {
    selectedVehicle.value = vehicle;
    isSearching.value = false;

    // Reset calculation values
    costPerKm.value = 0.0;
    costPer100Km.value = 0.0;
    costPerMonth.value = 0.0;

    // Set maintenance cost based on vehicle type_id if available in search results
    if (vehicle['type_id'] != null) {
      int typeId = vehicle['type_id'];
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

      // Ambil app_key dari service
      final appKey = await _appTokenService.getAppKey();
      if (appKey == null) {
        hasError.value = true;
        errorMessage.value = 'Gagal mendapatkan app_key';
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrlDev/$slug'),
        headers: {'Accept': 'application/json', 'x-app-key': appKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['type_id'] != null) {
          int typeId = data['type_id'];
          String vehicleType = "";

          switch (typeId) {
            case 1:
              vehicleType = "mobil";
              maintenanceCostPerKm = 108.0;
              break;
            case 2:
              vehicleType = "sepeda motor";
              maintenanceCostPerKm = 42.0;
              break;
            case 3:
              vehicleType = "sepeda";
              maintenanceCostPerKm = 42.0;
              break;
            default:
              vehicleType = "lainnya";
              maintenanceCostPerKm = 42.0;
          }

          print(
            'DEBUG: Vehicle type_id from detail: $typeId - Vehicle type: $vehicleType',
          );
          print(
            'DEBUG: Maintenance cost set to: Rp $maintenanceCostPerKm per km',
          );
        }

        extractBatteryDetails(data);
        calculateCosts();
      } else {
        hasError.value = true;
        errorMessage.value = 'Gagal mendapatkan detail kendaraan';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Terjadi kesalahan: $e';
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
              batteryCapacityValue = double.tryParse(pivot['value'].toString());
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
              maxRange = double.tryParse(pivot['value'].toString());
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
          batteryCapacityValue = double.tryParse(
            capacityHighlight['value'].toString(),
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
          maxRange = double.tryParse(rangeHighlight['value'].toString());
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
}
