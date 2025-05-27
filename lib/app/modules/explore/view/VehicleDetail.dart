import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infoev/app/modules/explore/controllers/VehicleDetailController.dart';
import 'package:flutter/services.dart';
import 'package:infoev/app/modules/favorite_vehicles/controllers/FavoriteVehiclesController.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({super.key});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage>
    with SingleTickerProviderStateMixin {
  final VehicleDetailController controller = Get.put(VehicleDetailController());
  final FavoriteVehicleController favoriteController = Get.put(FavoriteVehicleController());
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
                backgroundColor: const Color(0xFF1A1A1A),
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
                          Colors.blue.withOpacity(0.2),
                          Colors.purple.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                title: Text(
                  'Detail Kendaraan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  Obx(
                    () => IconButton(
                      icon: Icon(
                        controller.vehicleLoved.value
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            controller.vehicleLoved.value
                                ? Colors.red
                                : Colors.white,
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final vehicleId = controller.vehicleId.value;

                        try {
                          if (controller.vehicleLoved.value) {
                            await favoriteController.removeFavorite(vehicleId);
                            controller.vehicleLoved.value = false;
                            showCustomSnackbar(
                              title: 'Berhasil',
                              message: 'Kendaraan dihapus dari favorit',
                              backgroundColor: Colors.red.shade400,
                              icon: Icons.favorite,
                            );
                          } else {
                            await favoriteController.addFavorite(vehicleId);
                            controller.vehicleLoved.value = true;
                            showCustomSnackbar(
                              title: 'Berhasil',
                              message: 'Kendaraan ditambahkan ke favorit',
                              backgroundColor: Colors.green.shade600,
                              icon: Icons.favorite,
                            );
                          }
                        } catch (e) {
                          showCustomSnackbar(
                            title: 'Error',
                            message: 'Terjadi kesalahan: $e',
                            backgroundColor: Colors.orange.shade700,
                            icon: Icons.error_outline,
                          );
                        }
                      },
                    ),
                  ),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
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
                                            Colors.white,
                                            Colors.grey[100]!,
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
                                            color: const Color(0xFF212121),
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.white54,
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
                            color: Colors.white,
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
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Center layout for 1 or 2 items
                              controller.affiliateLinks.length == 1
                                  ? Center(
                                      child: _buildAffiliateButton(
                                        controller.affiliateLinks[0]
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildAffiliateButton(
                                          controller.affiliateLinks[0]
                                        ),
                                        const SizedBox(width: 16),
                                        _buildAffiliateButton(
                                          controller.affiliateLinks[1]
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
                                          color: Colors.white70,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          category.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF212121),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
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
                                                              Colors.grey[850]!,
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
                                                                  Colors
                                                                      .grey[400],
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
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  color:
                                                                      Colors
                                                                          .white,
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
                            color: Colors.grey[500],
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
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Komentar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '24 komentar', // This will be dynamic later
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Comment Input
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF212121),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
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
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    enabled: false, // Disabled for now
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Tulis komentar Anda...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1A1A1A),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: null, // Disabled for now
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue[700],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Kirim',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Sample Comments
                            ...List.generate(3, (index) => _buildCommentCard()),

                            // Show More Button
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: TextButton(
                                  onPressed: null, // Disabled for now
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue[400],
                                  ),
                                  child: Text(
                                    'Lihat komentar lainnya',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
            placeholder: (context, url) => Container(
              color: Colors.white,
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.shopping_bag,
              color: Colors.grey[400],
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'JD',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '2 jam yang lalu',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kendaraan ini memiliki performa yang sangat baik dan hemat energi. Sangat cocok untuk penggunaan sehari-hari di kota.',
            style: GoogleFonts.poppins(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () {
                  // TODO: Implement like functionality
                  HapticFeedback.lightImpact();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '12',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  // TODO: Implement reply functionality
                  HapticFeedback.lightImpact();
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_outlined,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Balas',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHighlightCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Gradient gradient,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value != '0' ? '$value $unit' : '-',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
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
                        color: Colors.white70,
                        fontSize: 11,
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
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
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.refreshData(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
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
      baseColor: const Color(0xFF262626),
      highlightColor: const Color(0xFF303030),
      child: Container(color: Colors.white),
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
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
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
}