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

class ArticalPage extends StatefulWidget {
  const ArticalPage({super.key});

  @override
  State<ArticalPage> createState() => _ArticalPageState();
}

class _ArticalPageState extends State<ArticalPage> {
  final NewsController newsController = Get.put(NewsController());
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      if (!newsController.isLoadingMore.value) {
        newsController.getAllNews();
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

  @override
  void dispose() {
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
            final newsList = newsController.allNewsList;
            final isLoading = newsController.isLoading.value;
            final hasError = newsController.isError.value;

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
                                      'sticky') {
                                    newsController.changeFilter('sticky');
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
                                                'sticky'
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
                                                    'sticky'
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
                                                      'sticky'
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
                        return Obx(
                          () =>
                              newsController.isLoadingMore.value
                                  ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                  : const SizedBox(),
                        );
                      }

                      final news = newsList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: NewsTitle(
                          ontap: () {
                            FocusScope.of(context).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            Get.to(NewsDetailsPage(news: news));
                          },
                          imageUrl: news.thumbnailUrl,
                          tag: "EV",
                          time: DateFormat(
                            "dd MMM yyyy",
                            'id_ID',
                          ).format(news.createdAt),
                          title: news.title,
                          author: "InfoEV.id",
                        ),
                      );
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
