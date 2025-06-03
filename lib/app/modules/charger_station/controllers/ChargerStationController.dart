import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/charger_station/model/ChargerStationModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

// City suggestion model
class CitySuggestion {
  final int id;
  final String name;

  CitySuggestion({required this.id, required this.name});

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(id: json['id'], name: json['name']);
  }
}

class ChargerStationController extends GetxController {
  var isLoading = true.obs;
  var searchQuery = ''.obs;
  var chargerStations = <ChargerStationModel>[].obs;
  var wilayah = "".obs;
  var errorMessage = "".obs;
  var hasError = false.obs;

  // Change from List<String> to List<CitySuggestion>
  var citySuggestions = <CitySuggestion>[].obs;
  var isSuggestLoading = false.obs;

  // Add cache duration and keys
  static const Duration cacheDuration = Duration(hours: 12);
  static const String _cacheCitySuggestions = 'cache_city_suggestions';
  static const String _cacheChargerStations = 'cache_charger_stations';

  // Add source tracking
  var suggestionSource = "".obs;

  @override
  void onInit() async {
    super.onInit();
    await _loadCachedData();
    fetchChargerStations("kediri");
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    _loadCitySuggestions(prefs);
    _loadChargerStations(prefs);
  }

  void _loadCitySuggestions(SharedPreferences prefs) {
    final cached = prefs.getString(_cacheCitySuggestions);
    final timestamp = prefs.getString('${_cacheCitySuggestions}_timestamp');

    if (cached != null && timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cachedTime) < cacheDuration) {
        final data = json.decode(cached) as List;
        citySuggestions.assignAll(
          data.map((x) => CitySuggestion.fromJson(x)).toList(),
        );
      }
    }
  }

  void _loadChargerStations(SharedPreferences prefs) {
    final cached = prefs.getString(_cacheChargerStations);
    final timestamp = prefs.getString('${_cacheChargerStations}_timestamp');

    if (cached != null && timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cachedTime) < cacheDuration) {
        final data = json.decode(cached) as List;
        chargerStations.assignAll(
          data.map((x) => ChargerStationModel.fromJson(x)).toList(),
        );
      }
    }
  }

  Future<void> _saveToCache(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }

  void fetchChargerStations(String location) async {
    try {
      isLoading(true);
      hasError(false);
      errorMessage("");

      print("Fetching charger stations for: $location");

      final encodedLocation = Uri.encodeComponent(location);

      final response = await http
          .get(
            Uri.parse(
              'https://infoev.mazkama.web.id/api/charger/search?wilayah=$encodedLocation',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      print("API Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final stationsResponse = ChargerStationResponse.fromJson(data);

        chargerStations.assignAll(stationsResponse.places);
        wilayah.value = stationsResponse.wilayah;

        print("Loaded ${chargerStations.length} stations for $wilayah");
      } else {
        isLoading(false);
        hasError(true);
        print("API Response status: ${response.statusCode}");
        chargerStations.clear();

        print(
          "Failed to load charger stations. Status: ${response.statusCode}",
        );
        if (response.statusCode == 404) {
          errorMessage.value = "Stasiun tidak ditemukan untuk lokasi ini.";
        } else {
          errorMessage.value =
              "Terjadi kesalahan saat memuat data stasiun. Coba lagi nanti.";
        }
      }
    } catch (e) {
      isLoading(false);
      hasError(true);
      errorMessage.value = "Terjadi kesalahan: $e";
      print("Exception during fetchChargerStations: $e");
    } finally {
      isLoading(false);
    }
  }

  List<ChargerStationModel> get filteredStations {
    if (searchQuery.value.isEmpty) {
      return chargerStations;
    }
    return chargerStations
        .where(
          (station) =>
              station.name.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ||
              station.vicinity.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
        )
        .toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void searchLocation(String location) {
    if (location.isNotEmpty) {
      fetchChargerStations(location);
      citySuggestions.clear();
    }
  }

  void suggestCities(String query) async {
    if (query.isEmpty || query.length < 2) {
      citySuggestions.clear();
      suggestionSource.value = "";
      return;
    }

    // Check cache first for matching suggestions
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheCitySuggestions);
    final timestamp = prefs.getString('${_cacheCitySuggestions}_timestamp');

    if (cached != null && timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cachedTime) < cacheDuration) {
        final data = json.decode(cached) as List;
        final filteredSuggestions =
            data
                .map((x) => CitySuggestion.fromJson(x))
                .where(
                  (city) =>
                      city.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

        // Hilangkan duplikat berdasarkan id
        final uniqueFiltered =
            {
              for (var city in filteredSuggestions) city.id: city,
            }.values.toList();

        if (uniqueFiltered.isNotEmpty) {
          citySuggestions.assignAll(uniqueFiltered);
          suggestionSource.value = "cache";
          print("City suggestions loaded from cache");
          return;
        }
      }
    }

    try {
      print("Fetching city suggestions from API...");
      isSuggestLoading(true);

      final encodedQuery = Uri.encodeComponent(query);
      final response = await http
          .get(
            Uri.parse(
              'https://infoev.mazkama.web.id/api/cities/search?cari=$encodedQuery',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions =
            data.map((item) => CitySuggestion.fromJson(item)).toList();

        // Hilangkan duplikat berdasarkan id
        final uniqueSuggestions =
            {for (var city in suggestions) city.id: city}.values.toList();

        citySuggestions.assignAll(uniqueSuggestions);
        suggestionSource.value = "api"; // Track API source

        // Save to cache
        await _saveToCache(_cacheCitySuggestions, data);

        print("Loaded ${citySuggestions.length} city suggestions from API");
      } else {
        citySuggestions.clear();
        suggestionSource.value = "error";
        print(
          "Failed to load city suggestions. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      citySuggestions.clear();
      suggestionSource.value = "error";
      print("Exception during suggestCities: $e");
    } finally {
      isSuggestLoading(false);
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheCitySuggestions);
    await prefs.remove('${_cacheCitySuggestions}_timestamp');
    await prefs.remove(_cacheChargerStations);
    await prefs.remove('${_cacheChargerStations}_timestamp');
  }
}
