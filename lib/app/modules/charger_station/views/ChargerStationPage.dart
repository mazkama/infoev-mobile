import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infoev/app/modules/charger_station/views/widgets/empty_stations_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:core';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:infoev/app/modules/charger_station/controllers/ChargerStationController.dart';
import 'package:infoev/app/modules/charger_station/model/ChargerStationModel.dart';
import 'package:infoev/app/styles/app_colors.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/shimmer_loading_stations.dart';
import 'widgets/charger_stations_list.dart';

class ChargerStationPage extends StatefulWidget {
  const ChargerStationPage({super.key});

  @override
  State<ChargerStationPage> createState() => _ChargerStationPageState();
}

class _ChargerStationPageState extends State<ChargerStationPage> {
  final ChargerStationController controller = Get.put(
    ChargerStationController(),
  );
  late GoogleMapController mapController;
  late DraggableScrollableController _draggableController;

  bool _showSearch = true;

  final LatLng _defaultCenter = const LatLng(-6.200000, 106.816666); // Jakarta
  final RxString selectedMarkerId = ''.obs;

  @override
  void initState() {
    super.initState();
    _draggableController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _zoomToStation(ChargerStationModel station) {
    final lat = station.lat ?? _defaultCenter.latitude;
    final lng = station.lng ?? _defaultCenter.longitude;
    final target = LatLng(lat, lng);

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 10)),
    );

    selectedMarkerId.value = station.placeId;
  }

  void _launchMapsUrl(station) async {
    try {
      // URL untuk aplikasi Google Maps dengan rute dari lokasi saat ini ke stasiun
      final mapsUrl =
          'https://www.google.com/maps/dir/?api=1&destination=${station.lat},${station.lng}&destination_place_id=${station.placeId}&travelmode=driving';
      final mapsUri = Uri.parse(mapsUrl);

      // Coba buka di aplikasi Google Maps
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback ke versi web jika aplikasi tidak dapat dibuka
        throw 'Could not launch maps';
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      // Tambahkan penanganan error di sini, misalnya menampilkan snackbar
    }
  }

  void _showDialog(station) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.1),
                        AppColors.secondaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon with modern design
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.ev_station_rounded,
                          color: AppColors.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Station name
                      Text(
                        station.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Location info with better styling
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.secondaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Lokasi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    station.vicinity,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons with modern design
                      Row(
                        children: [
                          // Cancel button
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                FocusScope.of(context).unfocus();
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: AppColors.primaryColor.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                              child: const Text(
                                'Tutup',
                                style: TextStyle(
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Maps button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                _launchMapsUrl(station);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: AppColors.textOnPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.directions_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Buka Maps',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Set<Marker> _buildMarkers() {
    return controller.filteredStations.map((station) {
      final markerId = MarkerId(station.placeId);

      return Marker(
        markerId: markerId,
        position: LatLng(station.lat ?? 0.0, station.lng ?? 0.0),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: station.vicinity,
          onTap: () {
            _showDialog(station);
          },
        ),
        onTap: () {
          selectedMarkerId.value = station.placeId;
          _showDialog(station);
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundColor,
        title: const Text(
          "Charger Stations",
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
      body: Obx(() {
        if (controller.filteredStations.isNotEmpty) {
          final firstStation = controller.filteredStations.first;
          _zoomToStation(firstStation);
        }

        return Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: 150),
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target:
                    controller.filteredStations.isNotEmpty
                        ? LatLng(
                          controller.filteredStations.first.lat ??
                              _defaultCenter.latitude,
                          controller.filteredStations.first.lng ??
                              _defaultCenter.longitude,
                        )
                        : _defaultCenter,
                zoom: 12,
              ),
              markers: _buildMarkers(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showSearch ? null : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _showSearch ? 1.0 : 0.0,
                  child: SearchBarWidget(controller: controller),
                ),
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                controller: _draggableController,
                initialChildSize: 0.50,
                minChildSize: 0.1,
                maxChildSize: 0.52,
                builder: (context, scrollController) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      // Deteksi swipe down (delta y positif)
                      if (details.delta.dy > 5) {
                        _draggableController.animateTo(
                          0.1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                      // Deteksi swipe up (delta y negatif)
                      else if (details.delta.dy < -5) {
                        _draggableController.animateTo(
                          0.6,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 5,
                              margin: const EdgeInsets.only(top: 10),
                              decoration: BoxDecoration(
                                color: AppColors.textTertiary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  controller.wilayah.isEmpty
                                      ? "Stasiun Pengisian"
                                      : "Stasiun di ${controller.wilayah}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height:
                                  300, // Atur tinggi minimum agar tetap bisa discroll
                              child:
                                  controller.isLoading.value
                                      ? ShimmerLoadingStations()
                                      : controller.filteredStations.isEmpty
                                      ? const EmptyStationsWidget()
                                      : ChargerStationsList(
                                        stations: controller.filteredStations,
                                        scrollController: scrollController,
                                        onStationTap: (station) {
                                          mapController.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                              CameraPosition(
                                                target: LatLng(
                                                  station.lat ??
                                                      _defaultCenter.latitude,
                                                  station.lng ??
                                                      _defaultCenter.longitude,
                                                ),
                                                zoom: 16,
                                              ),
                                            ),
                                          );
                                          mapController.showMarkerInfoWindow(
                                            MarkerId(station.placeId),
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
