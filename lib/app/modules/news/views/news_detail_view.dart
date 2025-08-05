import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:infoev/app/modules/news/model/NewsModel.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:infoev/app/styles/app_colors.dart'; // Import palet warna
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infoev/core/ad_helper.dart';

class NewsDetailsPage extends StatefulWidget {
  final NewsModel news;
  const NewsDetailsPage({super.key, required this.news});

  @override
  State<NewsDetailsPage> createState() => _NewsDetailsPageState();
}

class _NewsDetailsPageState extends State<NewsDetailsPage> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId(isTest: false), // isTest: true untuk development
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.backgroundColor,
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
                            baseColor: AppColors.shimmerBase,
                            highlightColor: AppColors.shimmerHighlight,
                            child: Container(color: AppColors.shimmerBase),
                          ),
                      errorWidget:
                          (context, url, error) => const Icon(
                            Icons.error,
                            color: AppColors.errorColor,
                          ),
                    ),
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(
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
                          Expanded(
                            child: Text(
                              "InfoEV.id",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat(
                              "EEEE, dd MMM yyyy HH:mm 'WIB'",
                              'id_ID',
                            ).format(widget.news.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        widget.news.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textColor,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 20),
                      HtmlWidget(
                        widget.news.content,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.textColor,
                          fontWeight: FontWeight.normal,
                        ),
                        customStylesBuilder: (element) {
                          if (element.localName == 'h1' ||
                              element.localName == 'h2' ||
                              element.localName == 'h3') {
                            return {
                              'font-family': 'Poppins',
                              'font-weight': '600',
                              'margin': '16px 0 8px 0',
                            };
                          }
                          return {
                            'font-family': 'Poppins',
                            'text-align': 'justify',
                          };
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_bannerAd != null)
                        Center(
                          child: SizedBox(
                            width: _bannerAd!.size.width.toDouble(),
                            height: _bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          ),
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
