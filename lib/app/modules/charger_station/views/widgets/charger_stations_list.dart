import 'package:flutter/material.dart';
import 'package:infoev/app/modules/charger_station/model/ChargerStationModel.dart';
import 'charger_station_card.dart';

class ChargerStationsList extends StatelessWidget {
  final List<ChargerStationModel> stations;
  final ScrollController? scrollController;
  final Function(ChargerStationModel)
  onStationTap; // Tambahan: callback untuk klik station

  const ChargerStationsList({
    super.key,
    required this.stations,
    this.scrollController,
    required this.onStationTap, // Wajib diisi
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              FocusScope.of(context).unfocus();
              onStationTap(stations[index]); // Panggil callback pas card di-tap
            },
            child: ChargerStationCard(station: stations[index]),
          );
        },
      ),
    );
  }
}
