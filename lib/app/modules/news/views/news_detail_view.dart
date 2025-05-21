import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna

class NewsDetailsPage extends StatefulWidget {
  final NewsModel news;
  const NewsDetailsPage({super.key, required this.news});

  @override
  State<NewsDetailsPage> createState() => _NewsDetailsPageState();
}

class _NewsDetailsPageState extends State<NewsDetailsPage> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () =>
              FocusScope.of(
                context,
              ).unfocus(), // Tutup keyboard saat tap area kosong
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor, // Latar belakang putih
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor:
                    AppColors.backgroundColor, // Ungu tua dari palet
                expandedHeight: 250,
                scrolledUnderElevation: 0, // Bayangan tetap saat scroll
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: widget.news.thumbnailUrl,
                    child: CachedNetworkImage(
                      imageUrl: widget.news.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              color: AppColors.cardBackgroundColor,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) =>
                              const Icon(Icons.error, color: Colors.redAccent),
                    ),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentColor.withOpacity(
                        0.5,
                      ), // Sesuaikan dengan tema
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.backgroundColor,
                      ), // Putih untuk kontras
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Get.back();
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // CircleAvatar(
                          //   radius: 10,
                          //   backgroundColor: AppColors.accentColor, // Oranye sebagai aksen
                          // ),
                          // const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "InfoEV.id",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentColor,
                              ), // Abu-abu gelap
                            ),
                          ),
                          Text(
                            DateFormat(
                              "EEEE, dd MMM yyyy HH:mm 'WIB'",
                              'id_ID',
                            ).format(widget.news.createdAt),
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.secondaryTextColor,
                            ), // Abu
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        widget.news.title,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor, // Hitam untuk keterbacaan
                        ),
                      ),

                      const SizedBox(height: 20),
                      HtmlWidget(
                        widget.news.content,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: AppColors.textColor,
                        ),
                        customStylesBuilder: (element) {
                          return {'text-align': 'justify'};
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
