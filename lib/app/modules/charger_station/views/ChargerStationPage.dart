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

  bool _showSearch = true;

  final LatLng _defaultCenter = const LatLng(-6.200000, 106.816666); // Jakarta
  final RxString selectedMarkerId = ''.obs;

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
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.backgroundColor,
          title: Row(
            children: [
              const Icon(Icons.ev_station, color: AppColors.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  station.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.textColor,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      station.vicinity,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
              },
              child: const Text(
                "Tutup",
                style: TextStyle(
                  color: AppColors.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _launchMapsUrl(station);
              },
              icon: const Icon(Icons.directions),
              label: Text('Rute Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[400],
                foregroundColor: Colors.black,
                textStyle: TextStyle(fontWeight: FontWeight.w500),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size(0, 30),
              ),
            ),
          ],
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
            icon: Icon(_showSearch ? Icons.search_off : Icons.search,
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
              child:
                  _showSearch
                      ? SearchBarWidget(controller: controller)
                      : Container(),
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.50,
              minChildSize: 0.15,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
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
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      Expanded(
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
                );
              },
            ),
          ],
        );
      }),
    );
  }
}
