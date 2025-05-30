import 'package:flutter/material.dart';
import 'package:infoev/app/modules/ev_comparison/model/VehicleModel.dart';
import 'package:infoev/app/styles/app_colors.dart';

class ComparisonTable extends StatelessWidget {
  final VehicleModel? vehicleA;
  final VehicleModel? vehicleB;

  const ComparisonTable({
    super.key,
    required this.vehicleA,
    required this.vehicleB,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicleA == null || vehicleB == null) return const SizedBox();

    final Map<int, SpecCategory> categoryMap = {};
    for (var cat in [...vehicleA!.specCategories, ...vehicleB!.specCategories]) {
      categoryMap.putIfAbsent(cat.id, () {
        return SpecCategory(
          id: cat.id,
          name: cat.name,
          priority: cat.priority,
          specs: [],
        );
      });
      categoryMap[cat.id]!.specs.addAll(cat.specs);
    }

    final categories = categoryMap.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final Map<int, SpecItem> specMap = {};
        for (var spec in category.specs) {
          if (specMap.containsKey(spec.id)) {
            final current = specMap[spec.id]!;
            final allVehicles = {...current.vehicles, ...spec.vehicles}.toList();
            specMap[spec.id] = SpecItem(
              id: spec.id,
              name: spec.name,
              unit: current.unit ?? spec.unit,
              type: current.type ?? spec.type,
              vehicles: allVehicles,
            );
          } else {
            specMap[spec.id] = spec;
          }
        }

        final mergedSpecs = specMap.values.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                // color: Colors.amber,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                // color: Colors.grey[600],
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: mergedSpecs.map((spec) {
                  final valueA = spec.getVehicleValueBySlug(vehicleA!.slug);
                  final valueB = spec.getVehicleValueBySlug(vehicleB!.slug);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        // top: BorderSide(color: Colors.grey[850]!),
                        top: BorderSide(color: AppColors.dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Nama spesifikasi
                        Expanded(
                          flex: 4,
                          child: Text(
                            spec.name,
                            style: const TextStyle(
                              // color: Colors.white70,
                              color: AppColors.textColor,
                              fontSize: 14,
                              // fontWeight: FontWeight.w500,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        // Nilai kendaraan A
                        Expanded(
                          flex: 4,
                          child: Text(
                            valueA ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              // color: Colors.white,
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Nilai kendaraan B
                        Expanded(
                          flex: 4,
                          child: Text(
                            valueB ?? '-',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              // color: Colors.white,
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
