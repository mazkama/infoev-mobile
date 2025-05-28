import 'package:infoev/app/modules/favorite_vehicles/views/FavoriteVehiclesPage.dart';
import 'package:infoev/app/modules/home/views/Widgets/new_vehicle_card.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_vehicle_new.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_vehicle_populer.dart';
import 'package:infoev/app/modules/home/views/Widgets/vehicle_populer_card.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/news/controllers/news_controller.dart';
import 'package:infoev/app/modules/home/views/Widgets/news_title.dart';
import 'package:infoev/app/modules/news/views/news_detail_view.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_loading.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final NewsController newsController = Get.put(NewsController());

  Future<void> _onRefresh() async {
    await newsController.loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    initializeDateFormatting('id_ID', null);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackgroundColor, // Gunakan ungu tua dari palet
        scrolledUnderElevation: 0, // Bayangan tetap saat scroll
        title: InkWell(
          onTap: () {
            // Aksi saat logo ditekan (opsional)
            // newsController.getNewsInfoEv();
          },
          child: Image.asset(
            'assets/images/logo_infoev.png', // Logo dari assets
            height: 20, // Sesuaikan ukuran logo
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: false, // Pastikan logo berada di tengah
        actions: [
          IconButton(
            onPressed: () {
              // Aksi saat ikon love ditekan (opsional)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritVehiclesPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.favorite_border, // Ikon hati (kosong)
              color: AppColors.accentColor, // Warna putih untuk kontras
              size: 25, // Ukuran ikon
            ),
          ),
          const SizedBox(width: 8), // Padding di sebelah kanan ikon
        ],
      ),
      backgroundColor: AppColors.backgroundColor, // Latar belakang putih
      body: Padding(
        padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.accentColor,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kendaaran Terbaru",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.textColor, // Warna teks hitam
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Shimmer untuk "Hottest News"
                Obx(() {
                  if (newsController.isLoading.value) {
                    return const ShimmerVehicleNew();
                  } else {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            newsController.newVehiclesList
                                .map(
                                  (e) => VehicleNewCard(
                                    onTap: () {
                                      Get.toNamed('/kendaraan/${e.slug}');
                                    },
                                    bannerUrl:
                                        e.thumbnailUrl,
                                    name: e.name,
                                    brand: e.brand?.name ?? 'InfoEV.id',
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  }
                }),

                const SizedBox(
                  height: 30,
                ), // Spacing lebih besar untuk pemisahan

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kendaaran Populer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.textColor, // Warna teks hitam
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Shimmer untuk "Hottest News"
                Obx(() {
                  if (newsController.isLoading.value) {
                    return const ShimmerVehiclePopuler();
                  } else {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            newsController.popularVehiclesList
                                .map(
                                  (e) => VehiclePopulerCard(
                                    onTap: () {
                                      Get.toNamed('/kendaraan/${e.slug}');
                                    },
                                    bannerUrl:
                                        e.thumbnailUrl,
                                    name: e.name ,
                                    brand: e.brand?.name ?? 'InfoEV.id',
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  }
                }),

                const SizedBox(
                  height: 30,
                ), // Spacing lebih besar untuk pemisahan

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Berita Terbaru",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AppColors.textColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/news');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(
                            0.1,
                          ), // Background oranye tipis
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Rounded corner
                        ),
                        child: Text(
                          "Lihat Semua",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Shimmer untuk "News For You"
                Obx(() {
                  if (newsController.isLoading.value) {
                    return const ShimmerLoading();
                  } else {
                    return Column(
                      children:
                          newsController.newNewsList
                              .map(
                                (e) => NewsTitle(
                                  ontap: () {
                                    FocusScope.of(context).unfocus();
                                    Get.to(NewsDetailsPage(news: e));
                                  },
                                  imageUrl: e.thumbnailUrl,
                                  tag: "EV",
                                  time: DateFormat(
                                    "dd MMM yyyy",
                                    'id_ID',
                                  ).format(e.createdAt),
                                  title: e.title,
                                  author: "InfoEV.id",
                                ),
                              )
                              .toList(),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
