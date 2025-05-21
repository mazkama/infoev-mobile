import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:core';
import 'package:infoev/app/modules/charger_station/model/ChargerStationModel.dart';
import 'info_chip.dart';

class ChargerStationCard extends StatelessWidget {
  final ChargerStationModel station;

  const ChargerStationCard({super.key, required this.station});

  void _launchMapsUrl() async {
    try {
      // URL untuk membuka detail tempat di Google Maps, bukan rute
      final mapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${station.lat},${station.lng}&query_place_id=${station.placeId}';
      final mapsUri = Uri.parse(mapsUrl);

      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      // Tambahkan penanganan error di sini, misalnya menampilkan snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOperational = station.isOperational();

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left side colored indicator
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                color:
                    isOperational
                        ? station.openNow == true
                            ? Colors.green[400]
                            : Colors.red[400]
                        // ? Colors.amber[400]
                        // : Colors.purple[400]
                        : Colors.grey[600],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Station icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.electrical_services,
                      size: 30,
                      color:
                          isOperational
                              ? station.openNow == true
                                  ? Colors.green[400]
                                  : Colors.red[400]
                              // ? Colors.amber[400]
                              // : Colors.purple[400]
                              : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Station details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          station.vicinity,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            InfoChip(
                              label:
                                  station.openNow == true
                                      ? "Buka"
                                      : (station.openNow == null
                                          ? "Status Tidak Diketahui"
                                          : "Tutup"),
                              backgroundColor:
                                  station.openNow == true
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey[800]!,
                              textColor:
                                  station.openNow == true
                                      ? Colors.green[400]!
                                      : Colors.grey[400]!,
                            ),
                            if (station.rating != null) ...[
                              const SizedBox(width: 8),
                              InfoChip(
                                label: "★ ${station.rating}",
                                backgroundColor: Colors.amber.withOpacity(0.2),
                                textColor: Colors.amber[400]!,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              station.businessStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[300],
                              ),
                            ),
                            // Maps button instead of distance text
                            ElevatedButton.icon(
                              onPressed: _launchMapsUrl,
                              icon: Icon(Icons.directions, size: 16),
                              label: Text('Detail Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[400],
                                // backgroundColor: Colors.purple[400],
                                foregroundColor: Colors.black,
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                minimumSize: Size(0, 30),
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
          ],
        ),
      ),
    );
  }
}
