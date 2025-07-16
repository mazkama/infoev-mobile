import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:infoev/app/services/cache_service.dart';
import 'package:infoev/app/services/app_token_service.dart';

class HomeController extends GetxController {
  RxList<NewsModel> newNewsList = <NewsModel>[].obs; 
  RxList<VehicleModel> popularVehiclesList = <VehicleModel>[].obs;
  RxList<VehicleModel> newVehiclesList = <VehicleModel>[].obs;
  RxBool isLoading = true.obs;  
  RxBool isError = false.obs;

  late final AppTokenService _appTokenService;

  @override
  void onInit() {
    super.onInit();
    _appTokenService = AppTokenService();
    _loadCachedData();
    loadAllData();
    CacheService.cleanExpiredCache();
  }

  Future<void> _loadCachedData() async {
    // Load cached data using the new CacheService
    final cachedNewNews = await CacheService.loadListFromCache(
      CacheService.newNewsKey,
      (json) => NewsModel.fromJson(json),
    );
    if (cachedNewNews != null) newNewsList.assignAll(cachedNewNews);

    final cachedPopularVehicles = await CacheService.loadListFromCache(
      CacheService.popularVehiclesKey,
      (json) => VehicleModel.fromJson(json),
    );
    if (cachedPopularVehicles != null)
      popularVehiclesList.assignAll(cachedPopularVehicles);

    final cachedNewVehicles = await CacheService.loadListFromCache(
      CacheService.newVehiclesKey,
      (json) => VehicleModel.fromJson(json),
    );
    if (cachedNewVehicles != null) newVehiclesList.assignAll(cachedNewVehicles);
  }

  Future<void> loadAllData() async {
    isLoading.value = true;

    final hasValidCache = await Future.wait([
      CacheService.isCacheValid(CacheService.newNewsKey),
      CacheService.isCacheValid(CacheService.popularVehiclesKey),
      CacheService.isCacheValid(CacheService.newVehiclesKey), 
    ]);
    
    // Cek apakah ada data yang perlu diperbarui
    final needsRefresh = hasValidCache.contains(false);
    
    if (needsRefresh) {
      // Jika perlu refresh, ambil semua data dengan satu API call
      await fetchAllHomeData();
    }
    
    isLoading.value = false;
  }

  Future<void> fetchAllHomeData() async {
    try {
      final response = await _appTokenService.requestWithAutoRefresh(
        requestFn: (appKey) => http.get(
          Uri.parse("$prodUrl"),
          headers: {'x-app-key': appKey},
        ),
        platform: "android",
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Proses semua data dari satu response
        await processNewsData(data);
        await processPopularVehicles(data);
        await processNewVehicles(data);
      } else {
        isError.value = true;
      }
    } catch (e) {
      isError.value = true;
    }
  }
  
  Future<void> processNewsData(Map<String, dynamic> data) async {
    if (data['posts'] != null) {
      final List<dynamic> newsData = data['posts'];
      final newsList = newsData.take(15).toList();
      final parsedList = newsList.map((json) => NewsModel.fromJson(json)).toList();
      
      newNewsList.assignAll(parsedList);
      
      await CacheService.saveToCache(
        CacheService.newNewsKey,
        parsedList,
        duration: CacheService.defaultCacheDuration,
      );
    }
  }
  
  Future<void> processPopularVehicles(Map<String, dynamic> data) async {
    if (data['popularVehicles'] != null) {
      final List<dynamic> vehicleData = data['popularVehicles'];
      final vehicleList = vehicleData.map((json) => VehicleModel.fromJson(json)).toList();
      
      popularVehiclesList.assignAll(vehicleList);
      
      await CacheService.saveToCache(
        CacheService.popularVehiclesKey,
        vehicleList,
        duration: CacheService.defaultCacheDuration,
      );
    }
  }
  
  Future<void> processNewVehicles(Map<String, dynamic> data) async {
    if (data['latestVehicles'] != null) {
      final List<dynamic> vehicleData = data['latestVehicles'];
      final vehicleList = vehicleData.map((json) => VehicleModel.fromJson(json)).toList();
      
      newVehiclesList.assignAll(vehicleList);
      
      await CacheService.saveToCache(
        CacheService.newVehiclesKey,
        vehicleList,
        duration: CacheService.defaultCacheDuration,
      );
    }
  }

  Future<void> clearCache() async {
    await CacheService.clearCache(CacheService.newNewsKey);
    await CacheService.clearCache(CacheService.popularVehiclesKey);
    await CacheService.clearCache(CacheService.newVehiclesKey);
  }
}