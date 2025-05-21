import 'package:flutter/material.dart';
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';

class EVCard extends StatelessWidget {
  final VehicleModel vehicle;

  const EVCard({super.key, required this.vehicle});

  String? getHighlightValue(String type) {
    final spec = vehicle.highlightSpecs.firstWhere(
      (s) => s.type == type,
      orElse: () => HighlightSpec(type: type, value: null, unit: null),
    );

    if (spec.value == null) return null;
    return '${spec.value} ${spec.unit ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final image = vehicle.thumbnailUrl;

    return Container(
      height: 270,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.white, // Background putih
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
            ),
          ),
          // Informasi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nama
                  Text(
                    '${vehicle.brand} ${vehicle.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Highlight Specs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _specColumn(
                        Icons.speed,
                        "Kecepatan",
                        getHighlightValue("maxSpeed"),
                        iconColor: Colors.yellow[400],
                      ),
                      _specColumn(
                        Icons.ev_station,
                        "Jarak",
                        getHighlightValue("range"),
                        iconColor: Colors.yellow[400],
                      ),
                      _specColumn(
                        Icons.bolt,
                        "Isi Ulang",
                        getHighlightValue("charge"),
                        iconColor: Colors.yellow[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specColumn(
    IconData icon,
    String label,
    String? value, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor ?? Colors.indigoAccent, size: 24),
        const SizedBox(height: 4),
        Text(
          value ?? "-",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
