import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infoev/app/modules/favorite_vehicles/controllers/FavoriteVehiclesController.dart';
import 'package:infoev/app/modules/favorite_vehicles/model/favoriteVehicleModel.dart';

class FavoritVehiclesPage extends StatelessWidget {
  const FavoritVehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FavoriteVehicleController());

    // Add this at the start of build method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.clearAndRefreshData();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Favorit Vehicles",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search action
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refreshFavorites();
        },
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.favoriteVehicles.isEmpty) {
            return const Center(child: Text("Tidak ada kendaraan favorit."));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: controller.favoriteVehicles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final vehicle = controller.favoriteVehicles[index];
                return _buildVehicleCard(vehicle, controller);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVehicleCard(FavoriteVehicle vehicle, FavoriteVehicleController controller) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/kendaraan/${vehicle.slug}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with delete icon overlay
              Expanded(
                child: Stack(
                  children: [
                    // Background putih untuk semua gambar
                    Positioned.fill(child: Container(color: Colors.white)),
                    // Thumbnail image
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: vehicle.thumbnailUrl,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => Container(color: Colors.white),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    // Delete icon button - di pojok kanan atas
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: panggil fungsi hapus favorite di controller
                          print('Hapus kendaraan: ${vehicle.name}');
                          controller.removeFavorite(vehicle.id); 
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Container(
                color: const Color(0xFF212121), // Background hitam untuk info
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
