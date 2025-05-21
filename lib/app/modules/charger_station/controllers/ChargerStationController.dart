import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/charger_station/model/ChargerStationModel.dart';  

// City suggestion model
class CitySuggestion {
  final int id;
  final String name;
  
  CitySuggestion({required this.id, required this.name});
  
  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      id: json['id'],
      name: json['name'],
    );
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

  @override
  void onInit() {
    super.onInit();
    fetchChargerStations("kediri");
  }
  
  void fetchChargerStations(String location) async {
    try {
      isLoading(true);
      hasError(false);
      errorMessage("");
      
      print("Fetching charger stations for: $location");

      final encodedLocation = Uri.encodeComponent(location);
      
      final response = await http.get(
        Uri.parse('https://infoev.mazkama.web.id/api/charger/search?wilayah=$encodedLocation'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      print("API Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final stationsResponse = ChargerStationResponse.fromJson(data);
        
        chargerStations.assignAll(stationsResponse.places);
        wilayah.value = stationsResponse.wilayah;
        
        print("Loaded ${chargerStations.length} stations for $wilayah");
        
        if (chargerStations.isEmpty) {
          errorMessage.value = "Tidak ada stasiun pengisian ditemukan di $location";
        }
      } else {
        hasError(true);
        errorMessage.value = "Gagal memuat data. Status: ${response.statusCode}";
      }
    } catch (e) {
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
    return chargerStations.where((station) =>
      station.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
      station.vicinity.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
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
      return;
    }
    
    try {
      print("Suggesting cities for: $query"); 
      isSuggestLoading(true);
      
      final encodedQuery = Uri.encodeComponent(query);
      
      final response = await http.get(
        Uri.parse('https://infoev.mazkama.web.id/api/cities/search?cari=$encodedQuery'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print("City API Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Parse city suggestions correctly based on the API response
        final suggestions = data.map((item) => CitySuggestion.fromJson(item)).toList();
        citySuggestions.assignAll(suggestions);
        
        print("Loaded ${citySuggestions.length} city suggestions");
      } else {
        citySuggestions.clear();
        print("Failed to load city suggestions. Status: ${response.statusCode}");
      }
    } catch (e) {
      citySuggestions.clear();
      print("Exception during suggestCities: $e");
    } finally {
      isSuggestLoading(false);
    }
  }
}