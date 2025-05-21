import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/news/controllers/news_controller.dart';
import 'package:infoev/app/modules/home/views/Widgets/news_title.dart';
import 'package:infoev/app/modules/home/views/Widgets/tranding_card.dart';
import 'package:infoev/app/modules/news/views/news_detail_view.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_loading.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_loading_horizontal.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    NewsController newsController = Get.put(NewsController());
    WidgetsFlutterBinding.ensureInitialized();
    initializeDateFormatting('id_ID', null);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Gunakan ungu tua dari palet
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
              // Misalnya, toggle status favorit
            },
            icon: const Icon(
              Icons.favorite_border, // Ikon hati (kosong)
              color: AppColors.primaryColor, // Warna putih untuk kontras
              size: 25, // Ukuran ikon
            ),
          ),
          const SizedBox(width: 8), // Padding di sebelah kanan ikon
        ],
      ),
      backgroundColor: AppColors.backgroundColor, // Latar belakang putih
      body: Padding(
        padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Efek smooth scroll
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Rata kiri untuk teks
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Berita Pilihan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.textColor, // Warna teks hitam
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
                        color: AppColors.accentColor.withOpacity(
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
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Shimmer untuk "Hottest News"
              Obx(() {
                if (newsController.isLoading.value) {
                  return const ShimmerLoadingHorizontal();
                } else {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          newsController.newsForYouList
                              .map(
                                (e) => TrandingCard(
                                  ontap: () {
                                    FocusScope.of(context).unfocus();
                                    Get.to(NewsDetailsPage(news: e));
                                  },
                                  imageUrl: e.thumbnailUrl,
                                  tag: "Infoev.id",
                                  time: DateFormat(
                                    "dd MMM yyyy",
                                    'id_ID',
                                  ).format(e.createdAt),
                                  title: e.title,
                                  author: "InfoEV.id",
                                ),
                              )
                              .toList(),
                    ),
                  );
                }
              }),

              const SizedBox(height: 30), // Spacing lebih besar untuk pemisahan

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
                        color: AppColors.accentColor.withOpacity(
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
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
    );
  }
}
