import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:infoev/app/modules/news/views/widgets/SearchWidget.dart';
import 'package:infoev/app/modules/news/controllers/news_controller.dart';
import 'package:infoev/app/modules/home/views/Widgets/news_title.dart';
import 'package:infoev/app/modules/home/views/Widgets/shimmer_loading.dart';
import 'package:infoev/app/modules/news/views/news_detail_view.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:infoev/app/modules/news/views/widgets/EmptyStateWidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infoev/core/ad_helper.dart';

class ArticalPage extends StatefulWidget {
  const ArticalPage({super.key});

  @override
  State<ArticalPage> createState() => _ArticalPageState();
}

class _ArticalPageState extends State<ArticalPage> {
  final NewsController newsController = Get.find<NewsController>();
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;

  // Tambahkan untuk AdMob
  final List<BannerAd?> _bannerAds = [];
  final List<bool> _isBannerAdLoadedList = [];
  final int adInterval = 6;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final filter = newsController.currentFilter.value;
    bool isLoadingMore = false;
    bool hasMore = false;

    if (filter == 'all') {
      isLoadingMore = newsController.isLoadingMoreAll.value;
      hasMore = newsController.hasMoreAll.value;
    } else if (filter == 'for_you') {
      isLoadingMore = newsController.isLoadingMoreForYou.value;
      hasMore = newsController.hasMoreForYou.value;
    } else if (filter == 'tips_and_tricks') {
      isLoadingMore = newsController.isLoadingMoreTips.value;
      hasMore = newsController.hasMoreTips.value;
    }

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore) {
        newsController.loadMore();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      newsController.searchNews(query);
    });
  }

  Future<void> _refreshNews() async {
    searchController.clear();
    newsController.searchQuery.value = '';
    await newsController.refreshNews();
  }

  void _createAndLoadBannerAd(int index) {
    final bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId(isTest: false), // isTest: true untuk development
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            if (_isBannerAdLoadedList.length <= index) {
              _isBannerAdLoadedList.add(true);
            } else {
              _isBannerAdLoadedList[index] = true;
            }
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            if (_isBannerAdLoadedList.length <= index) {
              _isBannerAdLoadedList.add(false);
            } else {
              _isBannerAdLoadedList[index] = false;
            }
          });
        },
      ),
    );

    if (_bannerAds.length <= index) {
      _bannerAds.add(bannerAd);
    } else {
      _bannerAds[index] = bannerAd;
    }

    bannerAd.load();
  }

  @override
  void dispose() {
    for (var ad in _bannerAds) {
      ad?.dispose();
    }
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Berita EV",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshNews,
          color: AppColors.secondaryColor,
          child: Obx(() {
            final query = newsController.searchQuery.value;
            final filter = newsController.currentFilter.value;
            final newsList =
                filter == 'all'
                    ? newsController.allNewsList
                    : filter == 'for_you'
                    ? newsController.newsForYou
                    : filter == 'tips_and_tricks'
                    ? newsController.newsTipsAndTricks
                    : newsController.allNewsList;
            final isLoading = newsController.isLoading.value;
            final hasError = newsController.isError.value;

            // Loading more & hasMore sesuai filter
            final isLoadingMore =
                filter == 'all'
                    ? newsController.isLoadingMoreAll.value
                    : filter == 'for_you'
                    ? newsController.isLoadingMoreForYou.value
                    : filter == 'tips_and_tricks'
                    ? newsController.isLoadingMoreTips.value
                    : false;
            final hasMore =
                filter == 'all'
                    ? newsController.hasMoreAll.value
                    : filter == 'for_you'
                    ? newsController.hasMoreForYou.value
                    : filter == 'tips_and_tricks'
                    ? newsController.hasMoreTips.value
                    : false;

            return CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_showSearch)
                        SearchWidget(
                          onSearch: _onSearchChanged,
                          controller: searchController,
                        ),
                      const SizedBox(height: 10),
                      if (query.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hasil cari "$query"',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Semua button
                              GestureDetector(
                                onTap: () {
                                  if (newsController.currentFilter.value !=
                                      'all') {
                                    newsController.changeFilter('all');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        newsController.currentFilter.value ==
                                                'all'
                                            ? AppColors.secondaryColor
                                            : AppColors.secondaryColor
                                                .withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.article_rounded,
                                        size: 16,
                                        color:
                                            newsController
                                                        .currentFilter
                                                        .value ==
                                                    'all'
                                                ? Colors.white
                                                : AppColors.secondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Semua',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              newsController
                                                          .currentFilter
                                                          .value ==
                                                      'all'
                                                  ? Colors.white
                                                  : AppColors.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Untukmu button
                              GestureDetector(
                                onTap: () {
                                  if (newsController.currentFilter.value !=
                                      'for_you') {
                                    newsController.changeFilter('for_you');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        newsController.currentFilter.value ==
                                                'for_you'
                                            ? AppColors.secondaryColor
                                            : AppColors.secondaryColor
                                                .withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.favorite_rounded,
                                        size: 16,
                                        color:
                                            newsController
                                                        .currentFilter
                                                        .value ==
                                                    'for_you'
                                                ? Colors.white
                                                : AppColors.secondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Untukmu',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              newsController
                                                          .currentFilter
                                                          .value ==
                                                      'for_you'
                                                  ? Colors.white
                                                  : AppColors.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Tips & Trik button
                              GestureDetector(
                                onTap: () {
                                  if (newsController.currentFilter.value !=
                                      'tips_and_tricks') {
                                    newsController.changeFilter(
                                      'tips_and_tricks',
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        newsController.currentFilter.value ==
                                                'tips_and_tricks'
                                            ? AppColors.secondaryColor
                                            : AppColors.secondaryColor
                                                .withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tips_and_updates,
                                        size: 16,
                                        color:
                                            newsController
                                                        .currentFilter
                                                        .value ==
                                                    'tips_and_tricks'
                                                ? Colors.white
                                                : AppColors.secondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tips & Trik',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              newsController
                                                          .currentFilter
                                                          .value ==
                                                      'tips_and_tricks'
                                                  ? Colors.white
                                                  : AppColors.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ]),
                  ),
                ),
                if (hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      message: "Gagal mengambil data berita.",
                      buttonText: "Coba Lagi",
                      onRetry: _refreshNews,
                    ),
                  ),
                if (!isLoading && newsList.isEmpty && query.isNotEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      message: 'Pencarian tidak ditemukan.',
                    ),
                  ),
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: ShimmerLoading()),
                  ),
                if (!isLoading && newsList.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index == newsList.length) {
                        // Loading more indicator
                        return Obx(
                          () => newsController.isLoadingMoreAll.value
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox(),
                        );
                      }

                      List<Widget> newsWithAds = [];
                      int adCount = index ~/ adInterval;

                      // Add news item
                      newsWithAds.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: NewsTitle(
                            ontap: () {
                              FocusScope.of(context).unfocus();
                              FocusManager.instance.primaryFocus?.unfocus();
                              Get.to(NewsDetailsPage(news: newsList[index]));
                            },
                            imageUrl: newsList[index].thumbnailUrl,
                            tag: "EV",
                            time: DateFormat(
                              "dd MMM yyyy",
                              'id_ID',
                            ).format(newsList[index].createdAt),
                            title: newsList[index].title,
                            author: "InfoEV.id",
                          ),
                        ),
                      );

                      // Tampilkan banner setiap kelipatan adInterval
                      if ((index + 1) % adInterval == 0) {
                        if (_bannerAds.length <= adCount) {
                          _createAndLoadBannerAd(adCount);
                        }

                        if (_isBannerAdLoadedList.length > adCount &&
                            _isBannerAdLoadedList[adCount] == true &&
                            _bannerAds.length > adCount &&
                            _bannerAds[adCount] != null) {
                          newsWithAds.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  width: _bannerAds[adCount]!.size.width.toDouble(),
                                  height: _bannerAds[adCount]!.size.height.toDouble(),
                                  child: AdWidget(ad: _bannerAds[adCount]!),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return Column(children: newsWithAds);
                    }, childCount: newsList.length + 1),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
