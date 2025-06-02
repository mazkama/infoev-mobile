import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/favorite_vehicles/model/favoriteVehicleModel.dart';
import 'package:infoev/core/halper.dart';
import 'dart:convert';
import 'package:infoev/core/local_db.dart';

class FavoriteVehicleController extends GetxController {
  var favoriteVehicles = <FavoriteVehicle>[].obs;
  var filteredVehicles = <FavoriteVehicle>[].obs; // For search results
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  var isLoadingMore = false.obs;
  var isError = false.obs;
  var hasMoreFavorites = true.obs;
  
  // Search state
  var isSearching = false.obs;
  var searchQuery = "".obs;

  int currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    fetchFavoriteVehicles(reset: true);
  }

  @override
  void onReady() {
    super.onReady();
    fetchFavoriteVehicles(); // Ini akan dipanggil ulang setiap kali halaman aktif
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
    filteredVehicles.value = favoriteVehicles
        .where((vehicle) => 
          vehicle.name.toLowerCase().contains(query) || 
          vehicle.brandName.toLowerCase().contains(query))
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
        favoriteVehicles.clear(); // Hapus data lama jika token tidak valid
        filteredVehicles.clear();
        errorMessage.value = 'Token tidak tersedia. Silakan login kembali.';
        return;
      }

      final response = await http.get(
        Uri.parse('${baseUrlDev}/favorites?page=$currentPage'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List vehiclesJson = body['data']['data'];

        if (vehiclesJson.isEmpty) {
          hasMoreFavorites.value = false;
        } else {
          // Jika reset, clear sudah dilakukan di atas, jadi ini tinggal addAll saja
          final newVehicles = vehiclesJson.map((e) => FavoriteVehicle.fromJson(e)).toList();
          favoriteVehicles.addAll(newVehicles);
          currentPage++;
          errorMessage.value = '';
          
          // Apply any active filters to update filtered list
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

    try {
      final response = await http.post(
        Uri.parse('${baseUrlDev}/favorites'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'vehicle_id': vehicleId}),
      );

      if (response.statusCode == 201) {
        // Refresh list favorit setelah berhasil tambah
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

    try {
      final response = await http.delete(
        Uri.parse('${baseUrlDev}/favorites/$vehicleId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Refresh list favorit setelah berhasil hapus
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
