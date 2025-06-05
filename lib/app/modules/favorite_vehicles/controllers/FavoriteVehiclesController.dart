import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/favorite_vehicles/model/favoriteVehicleModel.dart';
import 'package:infoev/core/halper.dart';
import 'dart:convert';
import 'package:infoev/core/local_db.dart';
import 'package:infoev/app/services/app_token_service.dart';

class FavoriteVehicleController extends GetxController {
  var favoriteVehicles = <FavoriteVehicle>[].obs;
  var filteredVehicles = <FavoriteVehicle>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  late final AppTokenService _appTokenService;

  var isLoadingMore = false.obs;
  var isError = false.obs;
  var hasMoreFavorites = true.obs;

  var isSearching = false.obs;
  var searchQuery = "".obs;

  int currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService();
    fetchFavoriteVehicles(reset: true);
  }

  @override
  void onReady() {
    super.onReady();
    fetchFavoriteVehicles();
  }

  // Toggle search mode
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      searchQuery.value = "";
      applyFilters();
    }
  }

  // Search vehicles by name or brand
  void searchVehicles(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Apply filters (currently just search)
  void applyFilters() {
    if (searchQuery.value.isEmpty) {
      filteredVehicles.value = List<FavoriteVehicle>.from(favoriteVehicles);
      return;
    }

    final query = searchQuery.value.toLowerCase();
    filteredVehicles.value =
        favoriteVehicles
            .where(
              (vehicle) =>
                  vehicle.name.toLowerCase().contains(query) ||
                  vehicle.brandName.toLowerCase().contains(query),
            )
            .toList();
  }

  // Reset all filters
  void resetFilters() {
    searchQuery.value = "";
    isSearching.value = false;
    applyFilters();
  }

  Future<void> refreshFavorites() async {
    await fetchFavoriteVehicles(reset: true);
  }

  Future<void> clearAndRefreshData() async {
    // Clear existing data
    favoriteVehicles.clear();
    filteredVehicles.clear();
    currentPage = 1;
    hasMoreFavorites.value = true;
    errorMessage.value = '';
    isLoading.value = false;
    isLoadingMore.value = false;
    isError.value = false;
    searchQuery.value = '';
    isSearching.value = false;

    // Fetch new data
    await fetchFavoriteVehicles(reset: true);
  }

  // Ambil daftar kendaraan favorit user
  Future<void> fetchFavoriteVehicles({bool reset = false}) async {
    // Cegah fetch bersamaan, baik loading biasa atau loading more
    if (isLoading.value || isLoadingMore.value) return;

    if (reset) {
      currentPage = 1;
      hasMoreFavorites.value = true;
      favoriteVehicles.clear();
      filteredVehicles.clear();
      errorMessage.value = '';
      isLoading.value = true;
    } else {
      if (!hasMoreFavorites.value) return;
      isLoadingMore.value = true;
    }

    try {
      final token = LocalDB.getToken();

      if (token == null || token.isEmpty) {
        favoriteVehicles.clear();
        filteredVehicles.clear();
        errorMessage.value = 'Token tidak tersedia. Silakan login kembali.';
        return;
      }

      // Ambil app_key dari service
      final appKey = await _appTokenService.getAppKey();
      if (appKey == null) {
        errorMessage.value = 'Gagal mendapatkan app_key';
        return;
      }

      final response = await http.get(
        Uri.parse('${baseUrlDev}/favorites?page=$currentPage'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'x-app-key': appKey,
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List vehiclesJson = body['data']['data'];

        if (vehiclesJson.isEmpty) {
          hasMoreFavorites.value = false;
        } else {
          final newVehicles =
              vehiclesJson.map((e) => FavoriteVehicle.fromJson(e)).toList();
          favoriteVehicles.addAll(newVehicles);
          currentPage++;
          errorMessage.value = '';
          applyFilters();
        }
      } else {
        errorMessage.value =
            'Gagal mengambil data. Status code: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    } finally {
      if (reset) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  // Tambah kendaraan ke favorit
  Future<void> addFavorite(int vehicleId) async {
    final token = LocalDB.getToken();

    if (token == null || token.isEmpty) {
      errorMessage.value = 'Token tidak tersedia. Silakan login kembali.';
      return;
    }

    // Ambil app_key dari service
    final appKey = await _appTokenService.getAppKey();
    if (appKey == null) {
      errorMessage.value = 'Gagal mendapatkan app_key';
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${baseUrlDev}/favorites'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'x-app-key': appKey,
        },
        body: json.encode({'vehicle_id': vehicleId}),
      );

      if (response.statusCode == 201) {
        await refreshFavorites();
        errorMessage.value = '';
      } else {
        errorMessage.value =
            'Gagal menambah favorit. Status code: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    }
  }

  // Hapus kendaraan dari favorit
  Future<void> removeFavorite(int vehicleId) async {
    final token = LocalDB.getToken();

    if (token == null || token.isEmpty) {
      errorMessage.value = 'Token tidak tersedia. Silakan login kembali.';
      return;
    }

    // Ambil app_key dari service
    final appKey = await _appTokenService.getAppKey();
    if (appKey == null) {
      errorMessage.value = 'Gagal mendapatkan app_key';
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${baseUrlDev}/favorites/$vehicleId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'x-app-key': appKey,
        },
      );

      if (response.statusCode == 200) {
        await refreshFavorites();
        errorMessage.value = '';
      } else {
        errorMessage.value =
            'Gagal menghapus favorit. Status code: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Terjadi kesalahan: $e';
    }
  }
}
