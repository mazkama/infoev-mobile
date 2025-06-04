import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:infoev/app/services/cache_service.dart';

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

  @override
  void onInit() {
    super.onInit();
    _loadCachedData();
    loadAllData();
    
    // Clean expired cache on startup
    CacheService.cleanExpiredCache();
  }

  Future<void> _loadCachedData() async {
    // Load cached data using the new CacheService
    final cachedNewNews = await CacheService.loadListFromCache(
      CacheService.newNewsKey, 
      (json) => NewsModel.fromJson(json)
    );
    if (cachedNewNews != null) newNewsList.assignAll(cachedNewNews);

    final cachedNewsForYou = await CacheService.loadListFromCache(
      CacheService.newsForYouKey, 
      (json) => NewsModel.fromJson(json)
    );
    if (cachedNewsForYou != null) newsForYouList.assignAll(cachedNewsForYou);

    final cachedAllNews = await CacheService.loadListFromCache(
      CacheService.allNewsKey, 
      (json) => NewsModel.fromJson(json)
    );
    if (cachedAllNews != null) allNewsList.assignAll(cachedAllNews);

    final cachedPopularVehicles = await CacheService.loadListFromCache(
      CacheService.popularVehiclesKey, 
      (json) => VehicleModel.fromJson(json)
    );
    if (cachedPopularVehicles != null) popularVehiclesList.assignAll(cachedPopularVehicles);

    final cachedNewVehicles = await CacheService.loadListFromCache(
      CacheService.newVehiclesKey, 
      (json) => VehicleModel.fromJson(json)
    );
    if (cachedNewVehicles != null) newVehiclesList.assignAll(cachedNewVehicles);
  }

  Future<void> loadAllData() async {
    isLoading.value = true;
    
    // Check if we have valid cached data first
    final hasValidCache = await Future.wait([
      CacheService.isCacheValid(CacheService.newNewsKey),
      CacheService.isCacheValid(CacheService.popularVehiclesKey),
      CacheService.isCacheValid(CacheService.newVehiclesKey),
      CacheService.isCacheValid(CacheService.allNewsKey),
    ]);

    // Only fetch data that doesn't have valid cache
    final tasks = <Future>[];
    
    if (!hasValidCache[0]) tasks.add(getNewNews());
    if (!hasValidCache[1]) tasks.add(getPopularVehicles());
    if (!hasValidCache[2]) tasks.add(getNewVehicles());
    if (!hasValidCache[3]) tasks.add(getAllNews(reset: true));

    // If all data is cached, skip API calls
    if (tasks.isEmpty) {
      isLoading.value = false;
      return;
    }

    await Future.wait(tasks);
    isLoading.value = false;
  }

  // Enhanced refresh method with cache clearing
  Future<void> refreshNews() async {
    isLoading.value = true;
    isError.value = false; // Reset error state
    searchQuery.value = ''; // Clear search
    allNewsList.clear(); // Clear existing list
    
    // Clear cache to force fresh data
    await clearCache();
    
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
    if (await CacheService.isCacheValid(CacheService.newNewsKey) && newNewsList.isNotEmpty) {
      return; // Use cached data
    }

    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newsData = data['posts'];
      final newsList = newsData.take(15).toList();

      newNewsList.assignAll(
        newsList.map((json) => NewsModel.fromJson(json)).toList(),
      );

      // Save to cache using CacheService
      await CacheService.saveToCache(
        CacheService.newNewsKey, 
        newsList.map((json) => NewsModel.fromJson(json)).toList(),
        duration: CacheService.defaultCacheDuration,
      );
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
      final newsList = newsData.take(15).map((json) => NewsModel.fromJson(json)).toList();
      
      newsForYouList.assignAll(newsList);

      // Save to cache using CacheService
      await CacheService.saveToCache(
        CacheService.newsForYouKey, 
        newsList,
        duration: CacheService.defaultCacheDuration,
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

          // Only cache first page using CacheService
          if (currentPage == 2) {
            await CacheService.saveToCache(
              CacheService.allNewsKey, 
              newsList,
              duration: CacheService.defaultCacheDuration,
            );
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
    // Check cache first
    if (await CacheService.isCacheValid(CacheService.popularVehiclesKey) && popularVehiclesList.isNotEmpty) {
      return; // Use cached data
    }

    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehicleData = data['popularVehicles'];
      final vehicleList = vehicleData.map((json) => VehicleModel.fromJson(json)).toList();
      
      popularVehiclesList.assignAll(vehicleList);

      // Save to cache using CacheService
      await CacheService.saveToCache(
        CacheService.popularVehiclesKey, 
        vehicleList,
        duration: CacheService.defaultCacheDuration,
      );
    } else {
      isError.value = true;
    }
  }

  Future<void> getNewVehicles() async {
    // Check cache first
    if (await CacheService.isCacheValid(CacheService.newVehiclesKey) && newVehiclesList.isNotEmpty) {
      return; // Use cached data
    }

    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehicleData = data['latestVehicles'];
      final vehicleList = vehicleData.map((json) => VehicleModel.fromJson(json)).toList();
      
      newVehiclesList.assignAll(vehicleList);

      // Save to cache using CacheService
      await CacheService.saveToCache(
        CacheService.newVehiclesKey, 
        vehicleList,
        duration: CacheService.defaultCacheDuration,
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
    // Use CacheService to clear all news-related cache
    await CacheService.clearCache(CacheService.newNewsKey);
    await CacheService.clearCache(CacheService.newsForYouKey);
    await CacheService.clearCache(CacheService.allNewsKey);
    await CacheService.clearCache(CacheService.popularVehiclesKey);
    await CacheService.clearCache(CacheService.newVehiclesKey);
  }
}
