import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    if (vehicleA == null || vehicleB == null) return const SizedBox();

    final Map<int, SpecCategory> categoryMap = {};
    for (var cat in [
      ...vehicleA!.specCategories,
      ...vehicleB!.specCategories,
    ]) {
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

    final categories =
        categoryMap.values.toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final Map<int, SpecItem> specMap = {};
        for (var spec in category.specs) {
          if (specMap.containsKey(spec.id)) {
            final current = specMap[spec.id]!;
            final allVehicles =
                {...current.vehicles, ...spec.vehicles}.toList();
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
            // Category Header with Icon
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
            // Specs Container
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: mergedSpecs.map((spec) {
                  return _buildSpecRow(spec, vehicleA!.slug, vehicleB!.slug);
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSpecRow(SpecItem spec, String slug1, String slug2) {
    final valueA = spec.getVehicleValueBySlug(slug1);
    final valueB = spec.getVehicleValueBySlug(slug2);
    final type = spec.type?.toLowerCase() ?? '';

    // Style khusus sesuai tipe data
    TextStyle valueStyle = GoogleFonts.poppins(
      color: AppColors.textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    // Warna khusus untuk tipe boolean/availability
    Widget valueAWidget = Text(
      valueA ?? '-',
      textAlign: TextAlign.center,
      style: valueStyle.copyWith(
        color: type == 'availability' && valueA == 'Ya'
            ? AppColors.successColor
            : AppColors.textColor,
      ),
    );

    Widget valueBWidget = Text(
      valueB ?? '-',
      textAlign: TextAlign.center,
      style: valueStyle.copyWith(
        color: type == 'availability' && valueB == 'Ya'
            ? AppColors.successColor
            : AppColors.textColor,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Spec Name
          Expanded(
            flex: 4,
            child: Text(
              spec.name,
              style: GoogleFonts.poppins(
                color: AppColors.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Vehicle A Value
          Expanded(
            flex: 4,
            child: valueAWidget,
          ),
          // Vehicle B Value
          Expanded(
            flex: 4,
            child: valueBWidget,
          ),
        ],
      ),
    );
  }
}
