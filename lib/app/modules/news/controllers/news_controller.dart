import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:infoev/core/halper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsController extends GetxController {
  // List & state for each type
  RxList<NewsModel> allNewsList = <NewsModel>[].obs;
  RxList<NewsModel> newsForYou = <NewsModel>[].obs;
  RxList<NewsModel> newsTipsAndTricks = <NewsModel>[].obs;

  // Pagination state for each type
  int currentPageAll = 1;
  int currentPageForYou = 1;
  int currentPageTips = 1;

  RxBool isLoading = true.obs;
  RxBool isLoadingMoreAll = false.obs;
  RxBool isLoadingMoreForYou = false.obs;
  RxBool isLoadingMoreTips = false.obs;

  RxBool hasMoreAll = true.obs;
  RxBool hasMoreForYou = true.obs;
  RxBool hasMoreTips = true.obs;

  RxBool isError = false.obs;
  var searchQuery = ''.obs;
  RxString currentFilter = 'all'.obs;

  static const cacheDuration = Duration(hours: 12);
  static const String _cacheKeyAllNews = 'cache_all_news';
  static const String _cacheKeyNewsForYou = 'cache_news_for_you';
  static const String _cacheKeyNewsTips = 'cache_news_tips';

  @override
void onInit() {
  super.onInit();
  _loadCachedData().then((_) {
    if (allNewsList.isEmpty && newsForYou.isEmpty && newsTipsAndTricks.isEmpty) {
      loadAllData();
    }
  });
}

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    _loadCachedList(prefs, _cacheKeyAllNews, allNewsList);
    _loadCachedList(prefs, _cacheKeyNewsForYou, newsForYou);
    _loadCachedList(prefs, _cacheKeyNewsTips, newsTipsAndTricks);
    isLoading.value = false;
  }

  void _loadCachedList<T>(SharedPreferences prefs, String key, RxList<T> list) {
    final cached = prefs.getString(key);
    final timestamp = prefs.getString('${key}_timestamp');
    if (cached != null && timestamp != null) {
      final cachedTime = DateTime.parse(timestamp);
      if (DateTime.now().difference(cachedTime) < cacheDuration) {
        final data = json.decode(cached) as List;
        if (T == NewsModel) {
          print('[CACHE] Load $key: ${data.length} items');
          list.assignAll(data.map((x) => NewsModel.fromJson(x)).cast<T>());
        } else if (T == VehicleModel) {
          print('[CACHE] Load $key: ${data.length} items');
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
      getAllNews(reset: true),
      getNewsForYou(reset: true),
      getNewsTipsAndTricks(reset: true),
    ]);
    isLoading.value = false;
  }

  Future<void> refreshNews() async {
    isLoading.value = true;
    isError.value = false;
    searchQuery.value = '';
    allNewsList.clear();
    newsForYou.clear();
    newsTipsAndTricks.clear();
    currentPageAll = 1;
    currentPageForYou = 1;
    currentPageTips = 1;
    hasMoreAll.value = true;
    hasMoreForYou.value = true;
    hasMoreTips.value = true;
    try {
      await loadAllData();
    } catch (e) {
      isError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // --- PAGINATION FOR ALL ---
  Future<void> getAllNews({bool reset = false}) async {
    if (reset) {
      currentPageAll = 1;
      hasMoreAll.value = true;
      allNewsList.clear();
    }
    if (!hasMoreAll.value || isLoadingMoreAll.value) return;
    isLoadingMoreAll.value = true;
    try {
      String url = "$baseUrlDev/berita?page=$currentPageAll";
      print('[ENDPOINT] Fetch all news: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];
        if (newsData.isEmpty) {
          hasMoreAll.value = false;
        } else {
          final newsList =
              newsData.map((json) => NewsModel.fromJson(json)).toList();
          allNewsList.addAll(newsList);
          currentPageAll++;
          if (currentPageAll == 2) {
            await _saveToCache(_cacheKeyAllNews, newsData);
          }
        }
      } else {
        isError.value = true;
      }
    } catch (e) {
      isError.value = true;
    } finally {
      isLoadingMoreAll.value = false;
    }
  }

  // --- PAGINATION FOR YOU ---
  Future<void> getNewsForYou({bool reset = false}) async {
    if (reset) {
      currentPageForYou = 1;
      hasMoreForYou.value = true;
      newsForYou.clear();
    }
    if (!hasMoreForYou.value || isLoadingMoreForYou.value) return;
    isLoadingMoreForYou.value = true;
    try {
      final url = "$baseUrlDev/berita?type=sticky&page=$currentPageForYou";
      print('[ENDPOINT] Fetch news for you: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];
        if (newsData.isEmpty) {
          hasMoreForYou.value = false;
        } else {
          final newsList =
              newsData.map((json) => NewsModel.fromJson(json)).toList();
          newsForYou.addAll(newsList);
          currentPageForYou++;
          if (currentPageForYou == 2) {
            await _saveToCache(_cacheKeyNewsForYou, newsData);
          }
        }
      }
    } catch (e) {
      // Biarkan cache jika error
    } finally {
      isLoadingMoreForYou.value = false;
    }
  }

  // --- PAGINATION TIPS & TRICKS ---
  Future<void> getNewsTipsAndTricks({bool reset = false}) async {
    if (reset) {
      currentPageTips = 1;
      hasMoreTips.value = true;
      newsTipsAndTricks.clear();
    }
    if (!hasMoreTips.value || isLoadingMoreTips.value) return;
    isLoadingMoreTips.value = true;
    try {
      final url =
          "$baseUrlDev/berita?type=tips_and_tricks&page=$currentPageTips";
      print('[ENDPOINT] Fetch news tips and tricks: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];
        if (newsData.isEmpty) {
          hasMoreTips.value = false;
        } else {
          final newsList =
              newsData.map((json) => NewsModel.fromJson(json)).toList();
          newsTipsAndTricks.addAll(newsList);
          currentPageTips++;
          if (currentPageTips == 2) {
            await _saveToCache(_cacheKeyNewsTips, newsData);
          }
        }
      }
    } catch (e) {
      // Biarkan cache jika error
    } finally {
      isLoadingMoreTips.value = false;
    }
  }

  Future<void> searchNews(String query) async {
    isLoading.value = true;
    searchQuery.value = query;
    currentFilter.value = 'all';
    try {
      final url = "$baseUrlDev/berita?q=$query";
      print('[ENDPOINT] Search news: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];
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

  /// Handling filter untuk setiap news type
  Future<void> changeFilter(String type, {bool forceRefresh = false}) async {
    if (currentFilter.value == type && !forceRefresh) return;
    isLoading.value = true;
    currentFilter.value = type;
    try {
      if (type == 'all') {
        if (allNewsList.isEmpty || forceRefresh) {
          await getAllNews(reset: true);
        }
      } else if (type == 'for_you') {
        if (newsForYou.isEmpty || forceRefresh) {
          await getNewsForYou(reset: true);
        }
      } else if (type == 'tips_and_tricks') {
        if (newsTipsAndTricks.isEmpty || forceRefresh) {
          await getNewsTipsAndTricks(reset: true);
        }
      } else {
        // fallback: filter custom type
        if (allNewsList.isEmpty || forceRefresh) {
          await getAllNews(reset: true);
        }
      }
    } catch (e) {
      isError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  // Call this from your view's scroll listener
  Future<void> loadMore() async {
    if (currentFilter.value == 'all') {
      await getAllNews();
    } else if (currentFilter.value == 'for_you') {
      await getNewsForYou();
    } else if (currentFilter.value == 'tips_and_tricks') {
      await getNewsTipsAndTricks();
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyAllNews);
    await prefs.remove(_cacheKeyNewsForYou);
    await prefs.remove(_cacheKeyNewsTips);
  }
}
