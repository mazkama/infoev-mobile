import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/VehicleDetailController.dart';
import 'package:flutter/services.dart';
import 'package:infoev/app/modules/explore/model/CommentModel.dart';
import 'package:infoev/app/modules/favorite_vehicles/controllers/FavoriteVehiclesController.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:infoev/app/widgets/login_alert_widget.dart';

class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({super.key});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage>
    with SingleTickerProviderStateMixin {
  final VehicleDetailController controller = Get.put(VehicleDetailController());
  FavoriteVehicleController? favoriteController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  int? replyingToCommentId;
  int? replyTargetId;
  final TextEditingController _replyController = TextEditingController();

  Set<int> visibleReplies = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    if (controller.isLoggedIn.value) {
      favoriteController = Get.put(FavoriteVehicleController());
    }
  }

  void _sendReply(int parentCommentId, int vehicleId) async {
    final replyText = _replyController.text;
    if (replyText.isEmpty) return;

    bool success = await controller.postComment(
      type: 'vehicle',
      id: vehicleId,
      comment: replyText,
      parent: parentCommentId,
    );

    if (success) {
      _replyController.clear();
      replyTargetId = null;

      // Refresh data lengkap, termasuk komentar
      await controller.fetchVehicleDetails(controller.vehicleSlug.value);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim balasan. Silakan coba lagi.')),
      );
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingState();
          }

          if (controller.hasError.value) {
            return _buildErrorState();
          }

          return CustomScrollView(
            slivers: [
              // Animated AppBar
              SliverAppBar(
                backgroundColor: AppColors.cardBackgroundColor,
                expandedHeight: 60,
                floating: true,
                pinned: true,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cardBackgroundColor.withOpacity(0.2),
                          // Colors.purple.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textColor,
                  ),
                  onPressed: () => Get.back(),
                ),
                title: Text(
                  'Detail Kendaraan',
                  style: GoogleFonts.poppins(
                    color: AppColors.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  Obx(() {
                    if (!controller.isLoggedIn.value) {
                      return SizedBox.shrink(); // Tidak tampil sama sekali
                    }
                    return IconButton(
                      icon: Icon(
                        controller.vehicleLoved.value
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            controller.vehicleLoved.value
                                ? Colors.red
                                : AppColors.primaryColor,
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final vehicleId = controller.vehicleId.value;

                        try {
                          if (controller.vehicleLoved.value) {
                            await favoriteController!.removeFavorite(vehicleId);
                            controller.vehicleLoved.value = false;
                            showCustomSnackbar(
                              title: 'Berhasil',
                              message: 'Kendaraan dihapus dari favorit',
                              backgroundColor: AppColors.errorColor,
                              icon: Icons.favorite,
                            );
                          } else {
                            await favoriteController!.addFavorite(vehicleId);
                            controller.vehicleLoved.value = true;
                            showCustomSnackbar(
                              title: 'Berhasil',
                              message: 'Kendaraan ditambahkan ke favorit',
                              backgroundColor: AppColors.successColor,
                              icon: Icons.favorite,
                            );
                          }
                        } catch (e) {
                          showCustomSnackbar(
                            title: 'Error',
                            message: 'Terjadi kesalahan: $e',
                            backgroundColor: AppColors.warningColor,
                            icon: Icons.error_outline,
                          );
                        }
                      },
                    );
                  }),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Image with Parallax effect
                      if (controller.vehicleImages.isNotEmpty)
                        Hero(
                          tag: 'vehicle-${controller.vehicleSlug}',
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowMedium.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // Gradient background
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.cardBackgroundColor,
                                            AppColors.cardBackgroundColor,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Vehicle Image
                                  Center(
                                    child: CachedNetworkImage(
                                      imageUrl: controller.vehicleImages[0],
                                      fit: BoxFit.contain,
                                      placeholder:
                                          (context, url) =>
                                              _buildImageShimmer(),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: AppColors.backgroundColor,
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: AppColors.primaryColor,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Vehicle Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          controller.vehicleName.value,
                          style: GoogleFonts.poppins(
                            color: AppColors.textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Highlight Cards with animation
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final isTablet = screenWidth >= 600;
                            final isLargeScreen = screenWidth > 1200;
                            
                            // Responsive grid configuration
                            final crossAxisCount = isTablet ? 4 : 2;
                            final childAspectRatio = isTablet ? (isLargeScreen ? 1.1 : 1.0) : 1.3;
                            final crossAxisSpacing = isTablet ? (isLargeScreen ? 16.0 : 12.0) : 12.0;
                            final mainAxisSpacing = isTablet ? (isLargeScreen ? 16.0 : 12.0) : 12.0;
                            
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: crossAxisSpacing,
                              mainAxisSpacing: mainAxisSpacing,
                              childAspectRatio: childAspectRatio,
                              children: [
                            _buildAnimatedHighlightCard(
                              icon: Icons.speed_rounded,
                              title: 'Kecepatan',
                              value: controller.getHighlightValue('maxSpeed'),
                              unit:
                                  controller.getHighlightUnit('maxSpeed') ??
                                  'km/h',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                              ),
                            ),
                            _buildAnimatedHighlightCard(
                              icon: Icons.battery_charging_full_rounded,
                              title: 'Kapasitas',
                              value: controller.getHighlightValue('capacity'),
                              unit:
                                  controller.getHighlightUnit('capacity') ??
                                  'kWh',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                              ),
                            ),
                            _buildAnimatedHighlightCard(
                              icon: Icons.map_rounded,
                              title: 'Jarak Tempuh',
                              value: controller.getHighlightValue('range'),
                              unit:
                                  controller.getHighlightUnit('range') ?? 'km',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                              ),
                            ),
                            _buildAnimatedHighlightCard(
                              icon: Icons.electrical_services_rounded,
                              title: 'Pengisian AC',
                              value: controller.getHighlightValue('charge'),
                              unit:
                                  controller.getHighlightUnit('charge') ??
                                  'jam',
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6B73FF), Color(0xFF000DFF)],
                              ),
                            ),
                          ],
                        );
                          },
                        ),
                      ),

                      // Affiliate Links - beli sekarang section
                      Obx(() {
                        if (controller.affiliateLinks.isEmpty ||
                            controller.affiliateLinks.length > 2) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Cek Harga Terbaru Di Sini',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Center layout for 1 or 2 items
                              controller.affiliateLinks.length == 1
                                  ? Center(
                                    child: _buildAffiliateButton(
                                      controller.affiliateLinks[0],
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildAffiliateButton(
                                        controller.affiliateLinks[0],
                                      ),
                                      const SizedBox(width: 16),
                                      _buildAffiliateButton(
                                        controller.affiliateLinks[1],
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 32),

                      // Specifications with animation
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              controller.specCategories.map((category) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(category.name),
                                          color: AppColors.secondaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          category.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBackgroundColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.shadowMedium
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children:
                                            category.specs
                                                .map((spec) {
                                                  final value = spec.getValue();
                                                  if (value == null)
                                                    return const SizedBox.shrink();

                                                  final formattedValue =
                                                      controller
                                                          .formatSpecValue(
                                                            value,
                                                          );
                                                  if (formattedValue.isEmpty)
                                                    return const SizedBox.shrink();

                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                          horizontal: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                          color:
                                                              AppColors
                                                                  .dividerColor,
                                                          width: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          flex: 2,
                                                          child: Text(
                                                            spec.name,
                                                            style: GoogleFonts.poppins(
                                                              color:
                                                                  AppColors
                                                                      .textColor,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 3,
                                                          child: Text(
                                                            formattedValue,
                                                            style: GoogleFonts.poppins(
                                                              color:
                                                                  AppColors
                                                                      .textColor,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                })
                                                .where(
                                                  (widget) =>
                                                      widget !=
                                                      const SizedBox.shrink(),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),

                      // Disclaimer
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          "InfoEV tidak menjamin informasi yang ada di halaman ini akurat 100%.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Comments Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: AppColors.secondaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Komentar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${controller.commentCount} komentar', // This will be dynamic later
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Comment Input
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowMedium.withOpacity(
                                      0.2,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tambahkan Komentar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _replyController,
                                    maxLines: 3,
                                    onChanged: (value) {
                                      setState(
                                        () {},
                                      ); // untuk update UI tombol kirim
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Tulis komentar Anda...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: AppColors.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.backgroundSecondary,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                    ),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed:
                                          _replyController.text.trim().isEmpty
                                              ? null
                                              : () async {
                                                if (!controller
                                                    .isLoggedIn
                                                    .value) {
                                                  // Hide keyboard first
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();

                                                  // Add delay
                                                  await Future.delayed(
                                                    const Duration(seconds: 1),
                                                  );
                                                  
                                                  LoginAlertWidget.show(
                                                    title: 'Masuk untuk Menambahkan Komentar',
                                                    subtitle: 'Untuk dapat memberikan komentar, silakan login terlebih dahulu',
                                                    icon: Icons.comment_rounded,
                                                  );
                                                  return; // Stop execution
                                                }

                                                final success = await controller
                                                    .postComment(
                                                      type: 'vehicle',
                                                      id:
                                                          controller
                                                              .vehicleId
                                                              .value,
                                                      comment:
                                                          _replyController.text
                                                              .trim(),
                                                      parent:
                                                          null, // isi jika reply ke comment tertentu
                                                    );

                                                if (success) {
                                                  _replyController.clear();
                                                  setState(() {}); // refresh UI

                                                  await controller
                                                      .fetchVehicleDetails(
                                                        controller
                                                            .vehicleSlug
                                                            .value,
                                                      );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Komentar berhasil dikirim',
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Gagal mengirim komentar. Silakan coba lagi.',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        foregroundColor: AppColors.primaryLight,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Text(
                                        'Kirim',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textOnPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Sample Comments
                            Obx(() {
                              final comments = controller.comments;

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final createdAt = comment.createdAt;
                                  final commentTimeAgo = timeAgo(
                                    createdAt,
                                  ); // konversi timestamp ke "x menit yang lalu"

                                  List<Widget> widgets = [
                                    _buildCommentCard(
                                      commentId: comment.id,
                                      name: comment.name,
                                      comment: comment.comment,
                                      timeAgo: commentTimeAgo,
                                      onReplyTap: () {
                                        setState(() {
                                          replyingToCommentId = comment.id;
                                          replyTargetId = comment.id;
                                        });
                                      },
                                      replies: comment.replies,
                                    ),
                                  ];

                                  return Column(children: widgets);
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAffiliateButton(dynamic link) {
    return InkWell(
      onTap: () async {
        final url = link['link'] ?? link['url'];
        if (url != null) {
          try {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            debugPrint('Error launching URL: $e');
          }
        }
        HapticFeedback.lightImpact();
      },
      child: Container(
        height: 60,
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: link['marketplace_logo'] ?? '',
            fit: BoxFit.contain,
            placeholder:
                (context, url) =>
                    Container(color: AppColors.cardBackgroundColor),
            errorWidget:
                (context, url, error) => Icon(
                  Icons.shopping_bag,
                  color: AppColors.primaryColor,
                  size: 32,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard({
    required int commentId,
    required String name,
    required String comment,
    required String timeAgo,
    bool isReply = false,
    String? replyTo,
    required VoidCallback onReplyTap,
    List<Reply> replies = const [],
  }) {
    final isRepliesVisible = visibleReplies.contains(commentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 12, left: isReply ? 48 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.secondaryColor,
                radius: 18,
                child: Text(
                  (name.isEmpty || name == 'Anonimus')
                      ? 'A'
                      : name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Anonimus' : name,
                      style: GoogleFonts.poppins(
                        color: AppColors.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isReply && replyTo != null && replyTo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0, bottom: 4),
                        child: Text(
                          'Membalas @$replyTo',
                          style: GoogleFonts.poppins(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    Text(
                      comment.isEmpty ? 'Komentar tidak tersedia' : comment,
                      style: GoogleFonts.poppins(
                        color: AppColors.textColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: GoogleFonts.poppins(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () async {
                            if (!controller.isLoggedIn.value) {
                              // Hide keyboard first
                              FocusScope.of(context).unfocus();

                              // Add delay
                              await Future.delayed(const Duration(seconds: 1));

                              LoginAlertWidget.show(
                                title: 'Masuk untuk Menambahkan Komentar',
                                subtitle: 'Untuk dapat memberikan komentar, silakan login terlebih dahulu',
                                icon: Icons.comment_rounded,
                              );
                              return; // Stop execution
                            }
                            onReplyTap();
                          },
                          child: Text(
                            'Balas',
                            style: GoogleFonts.poppins(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        if (replies.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isRepliesVisible) {
                                  visibleReplies.remove(commentId);
                                } else {
                                  visibleReplies.add(commentId);
                                }
                              });
                            },
                            child: Text(
                              isRepliesVisible
                                  ? 'Sembunyikan Balasan'
                                  : 'Lihat Balasan (${replies.length})',
                              style: GoogleFonts.poppins(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tampilkan form balasan jika sedang membalas
        if (replyTargetId == commentId)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis balasan...',
                    fillColor: AppColors.cardBackgroundColor,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => _sendReply(
                            replyingToCommentId!,
                            controller.vehicleId.value,
                          ),
                      child: const Text('Kirim'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          replyingToCommentId = null;
                          replyTargetId = null;
                          _replyController.clear();
                        });
                      },
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Tampilkan daftar balasan jika aktif
        if (isRepliesVisible)
          Column(
            children:
                replies.map((reply) {
                  return _buildCommentCard(
                    commentId: reply.id,
                    name: reply.name,
                    comment: reply.comment,
                    timeAgo: timeAgo,
                    isReply: true,
                    replyTo: name,
                    onReplyTap: () {
                      setState(() {
                        replyingToCommentId = commentId;
                        replyTargetId = reply.id;
                      });
                    },
                  );
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildAnimatedHighlightCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Gradient gradient,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth > 1200;
    
    // Responsive sizing
    final cardWidth = isTablet ? null : 160.0; // Let it flex for tablets
    final iconSize = isTablet ? (isLargeScreen ? 28.0 : 32.0) : 32.0;
    final titleFontSize = isTablet ? (isLargeScreen ? 12.sp : 8.sp) : 14.0;
    final valueFontSize = isTablet ? (isLargeScreen ? 16.sp : 12.sp) : 20.0;
    final descFontSize = isTablet ? (isLargeScreen ? 10.0 : 9.0) : 11.0;
    final cardPadding = isTablet ? (isLargeScreen ? 14.0 : 12.0) : 16.0;
    final horizontalMargin = isTablet ? 2.0 : 4.0;
    
    return Container(
      width: cardWidth,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.cardBackgroundColor, size: iconSize),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value != '0' ? '$value $unit' : '-',
                  style: GoogleFonts.poppins(
                    color: AppColors.textOnPrimary,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Tambahkan deskripsi jika ada
                if (title == 'Pengisian AC' &&
                    controller.getHighlightDesc('charge') != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      controller.getHighlightDesc('charge') ?? '',
                      style: GoogleFonts.poppins(
                        color: AppColors.textOnPrimary,
                        fontSize: descFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('motor') || name.contains('mesin')) {
      return Icons.engineering_rounded;
    } else if (name.contains('dimensi') || name.contains('ukuran')) {
      return Icons.straighten_rounded;
    } else if (name.contains('baterai') || name.contains('battery')) {
      return Icons.battery_charging_full_rounded;
    } else if (name.contains('performa') || name.contains('performance')) {
      return Icons.speed_rounded;
    } else if (name.contains('fitur') || name.contains('feature')) {
      return Icons.stars_rounded;
    } else if (name.contains('suspensi') || name.contains('chassis')) {
      return Icons.tire_repair_rounded;
    } else {
      return Icons.info_outline_rounded;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.secondaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              color: AppColors.textColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(color: AppColors.shimmerBase),
    );
  }

  void showCustomSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    IconData? icon,
  }) {
    Get.rawSnackbar(
      title: title,
      message: message,
      icon: icon != null ? Icon(icon, color: AppColors.secondaryColor) : null,
      duration: const Duration(seconds: 3),
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      snackPosition: SnackPosition.TOP,
    );
  }

  String timeAgo(String datetimeString) {
    final dateTime = DateTime.parse(datetimeString).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return '${diff.inSeconds} detik yang lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
