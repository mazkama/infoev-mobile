import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:infoev/app/modules/explore/model/VehicleModel.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:infoev/core/halper.dart';

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

  int currentPage = 1;

  @override
  void onInit() {
    super.onInit(); 
    loadAllData();
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
    searchQuery.value = ''; // Kosongkan pencarian
    allNewsList.clear(); // Kosongkan list sebelumnya
    try {
      await getAllNews(reset: true); // Misalnya kamu punya fungsi ini
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getNewNews() async {
    var baseURL = "${baseUrlDev}";
    final response = await http.get(Uri.parse(baseURL));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newsData = data['posts'];
      newNewsList.assignAll(
        newsData.take(15).map((json) => NewsModel.fromJson(json)).toList(),
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
      newsForYouList.assignAll(
        newsData.take(15).map((json) => NewsModel.fromJson(json)).toList(),
      );
    } else {
      isError.value = true;
    }
  }

  Future<void> getAllNews({bool reset = false}) async {
    if (reset) {
      currentPage = 1;
      hasMoreNews.value = true;
      allNewsList.clear();
    }

    if (!hasMoreNews.value || isLoadingMore.value) return;

    isLoadingMore.value = true;

    try {
      final response = await http.get(
        Uri.parse("${baseUrlDev}/berita?page=$currentPage"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsData = data['posts']['data'];

        if (newsData.isEmpty) {
          hasMoreNews.value = false;
        } else {
          allNewsList.addAll(
            newsData.map((json) => NewsModel.fromJson(json)).toList(),
          );
          currentPage++;
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
}
