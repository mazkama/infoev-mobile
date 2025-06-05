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

    final tasks = <Future>[];

    if (!hasValidCache[0]) tasks.add(getNewNews());
    if (!hasValidCache[1]) tasks.add(getPopularVehicles());
    if (!hasValidCache[2]) tasks.add(getNewVehicles()); 

    if (tasks.isEmpty) {
      isLoading.value = false;
      return;
    }

    await Future.wait(tasks);
    isLoading.value = false;
  }

  Future<void> getNewNews() async {
    if (await CacheService.isCacheValid(CacheService.newNewsKey) &&
        newNewsList.isNotEmpty) {
      return;
    }

    // Ambil app_key dari service
    final appKey = await _appTokenService.getAppKey();
    if (appKey == null) {
      isError.value = true;
      return;
    }

    var baseURL = "${baseUrlDev}";
    final response = await http.get(
      Uri.parse(baseURL),
      headers: {'x-app-key': appKey},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newsData = data['posts'];
      final newsList = newsData.take(15).toList();

      newNewsList.assignAll(
        newsList.map((json) => NewsModel.fromJson(json)).toList(),
      );

      await CacheService.saveToCache(
        CacheService.newNewsKey,
        newsList.map((json) => NewsModel.fromJson(json)).toList(),
        duration: CacheService.defaultCacheDuration,
      );
    } else {
      isError.value = true;
    }
  }

  Future<void> getPopularVehicles() async {
    if (await CacheService.isCacheValid(CacheService.popularVehiclesKey) &&
        popularVehiclesList.isNotEmpty) {
      return;
    }

    // Ambil app_key dari service
    final appKey = await _appTokenService.getAppKey();
    if (appKey == null) {
      isError.value = true;
      return;
    }

    var baseURL = "${baseUrlDev}";
    final response = await http.get(
      Uri.parse(baseURL),
      headers: {'x-app-key': appKey},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehicleData = data['popularVehicles'];
      final vehicleList =
          vehicleData.map((json) => VehicleModel.fromJson(json)).toList();

      popularVehiclesList.assignAll(vehicleList);

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
    if (await CacheService.isCacheValid(CacheService.newVehiclesKey) &&
        newVehiclesList.isNotEmpty) {
      return;
    }

    // Ambil app_key dari service
    final appKey = await _appTokenService.getAppKey();
    if (appKey == null) {
      isError.value = true;
      return;
    }

    var baseURL = "${baseUrlDev}";
    final response = await http.get(
      Uri.parse(baseURL),
      headers: {'x-app-key': appKey},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> vehicleData = data['latestVehicles'];
      final vehicleList =
          vehicleData.map((json) => VehicleModel.fromJson(json)).toList();

      newVehiclesList.assignAll(vehicleList);

      await CacheService.saveToCache(
        CacheService.newVehiclesKey,
        vehicleList,
        duration: CacheService.defaultCacheDuration,
      );
    } else {
      isError.value = true;
    }
  } 

  Future<void> clearCache() async {
    await CacheService.clearCache(CacheService.newNewsKey);
    await CacheService.clearCache(CacheService.popularVehiclesKey);
    await CacheService.clearCache(CacheService.newVehiclesKey);
  }
}
