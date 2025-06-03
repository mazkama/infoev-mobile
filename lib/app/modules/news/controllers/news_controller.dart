import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsController extends GetxController {
  RxList<NewsModel> newNewsList = <NewsModel>[].obs;
  RxList<NewsModel> newsForYouList = <NewsModel>[].obs;
  RxList<NewsModel> allNewsList = <NewsModel>[].obs;
  RxList<VehicleModel> popularVehiclesList = <VehicleModel>[].obs;
  RxList<VehicleModel> newVehiclesList = <VehicleModel>[].obs;
  RxBool isLoading = true.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasMoreNews = true.obs;
  RxBool isError = false.obs; // Menambahkan status error
  var searchQuery = ''.obs;

  // Change the currentFilter initialization
  RxString currentFilter = 'all'.obs;

  int currentPage = 1;

  // Add cache duration constant
  static const cacheDuration = Duration(hours: 12);

  // Add cache keys
  static const String _cacheKeyNewNews = 'cache_new_news';
  static const String _cacheKeyNewsForYou = 'cache_news_for_you';
  static const String _cacheKeyAllNews = 'cache_all_news';
  static const String _cacheKeyPopularVehicles = 'cache_popular_vehicles';
  static const String _cacheKeyNewVehicles = 'cache_new_vehicles';

  @override
  void onInit() {
    super.onInit();
    _loadCachedData();
    loadAllData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached data with timestamps
    _loadCachedList(prefs, _cacheKeyNewNews, newNewsList);
    _loadCachedList(prefs, _cacheKeyNewsForYou, newsForYouList);
    _loadCachedList(prefs, _cacheKeyAllNews, allNewsList);
    _loadCachedList(prefs, _cacheKeyPopularVehicles, popularVehiclesList);
    _loadCachedList(prefs, _cacheKeyNewVehicles, newVehiclesList);
  }

  void _loadCachedList<T>(SharedPreferences prefs, String key, RxList<T> list) {
    final cached = prefs.getString(key);
    final timestamp = prefs.getString('${key}_timestamp');

    if (cached != null && timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cachedTime) < cacheDuration) {
        final data = json.decode(cached) as List;
        if (T == NewsModel) {
          list.assignAll(data.map((x) => NewsModel.fromJson(x)).cast<T>());
        } else if (T == VehicleModel) {
          list.assignAll(data.map((x) => VehicleModel.fromJson(x)).cast<T>());
        }
      }
    }
  }

  Future<void> _saveToCache(String key, List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    await Future.wait([
      getNewNews(),
      getNewVehicles(),
      getPopularVehicles(),
      getAllNews(reset: true),
    ]);
    isLoading.value = false;
  }

  // Di dalam NewsController
  Future<void> refreshNews() async {
    isLoading.value = true;
    isError.value = false; // Reset error state
    searchQuery.value = ''; // Kosongkan pencarian
    allNewsList.clear(); // Kosongkan list sebelumnya
    try {
      await getAllNews(reset: true);
    } catch (e) {
      isError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getNewNews() async {
    // Check cache first
    if (newNewsList.isNotEmpty) return;

    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newsData = data['posts'];
      final newsList = newsData.take(15).toList();

      newNewsList.assignAll(
        newsList.map((json) => NewsModel.fromJson(json)).toList(),
      );

      // Save to cache
      await _saveToCache(_cacheKeyNewNews, newsList);
    } else {
      isError.value = true;
    }
  }

  Future<void> getNewsForYou() async {
    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newsData = data['stickies'];
      newsForYouList.assignAll(
        newsData.take(15).map((json) => NewsModel.fromJson(json)).toList(),
      );
    } else {
      isError.value = true;
    }
  }

  Future<void> getAllNews({bool reset = false, String? type}) async {
    if (reset) {
      currentPage = 1;
      hasMoreNews.value = true;
      allNewsList.clear();
      if (type != null) {
        currentFilter.value = type;
      }
    }

    if (!hasMoreNews.value || isLoadingMore.value) return;

    isLoadingMore.value = true;

    try {
      String url = "${baseUrlDev}/berita?page=$currentPage";
      final activeFilter = type ?? currentFilter.value;

      if (activeFilter.isNotEmpty && activeFilter != 'all') {
        url += "&type=$activeFilter";
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];

        if (newsData.isEmpty) {
          hasMoreNews.value = false;
        } else {
          final newsList =
              newsData.map((json) => NewsModel.fromJson(json)).toList();
          allNewsList.addAll(newsList);
          currentPage++;

          // Only cache first page
          if (currentPage == 2) {
            await _saveToCache(_cacheKeyAllNews, newsData);
          }
        }
      } else {
        isError.value = true;
      }
    } catch (e) {
      isError.value = true;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> getPopularVehicles() async {
    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehicleData = data['popularVehicles'];
      popularVehiclesList.assignAll(
        vehicleData.map((json) => VehicleModel.fromJson(json)).toList(),
      );
    } else {
      isError.value = true;
    }
  }

  Future<void> getNewVehicles() async {
    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehicleData = data['latestVehicles'];
      newVehiclesList.assignAll(
        vehicleData.map((json) => VehicleModel.fromJson(json)).toList(),
      );
    } else {
      isError.value = true;
    }
  }

  // Method untuk pencarian
  Future<void> searchNews(String query) async {
    isLoading.value = true;
    searchQuery.value = query;
    currentFilter.value = '';

    try {
      final response = await http.get(
        Uri.parse("${baseUrlDev}/berita?q=$query"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];

        // Menambahkan hasil pencarian ke dalam allNewsList
        allNewsList.assignAll(
          newsData.map((json) => NewsModel.fromJson(json)).toList(),
        );
      } else {
        isError.value = true;
      }
    } catch (e) {
      isError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // Update the changeFilter method
  Future<void> changeFilter(String type) async {
    if (currentFilter.value != type) {
      isLoading.value = true;
      try {
        await getAllNews(reset: true, type: type);
      } catch (e) {
        isError.value = true;
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyNewNews);
    await prefs.remove(_cacheKeyNewsForYou);
    await prefs.remove(_cacheKeyAllNews);
    await prefs.remove(_cacheKeyPopularVehicles);
    await prefs.remove(_cacheKeyNewVehicles);
  }
}
