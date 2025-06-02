import 'package:infoev/app/modules/explore/model/VehicleModel.dart';

class BrandDetailModel {
  final List<VehicleModel> vehicles;
  final String nameBrand;
  final String banner;
  final int brandId;

  BrandDetailModel({
    required this.vehicles,
    required this.nameBrand,
    required this.banner,
    required this.brandId,
  });

  factory BrandDetailModel.fromJson(Map<String, dynamic> json) {
    return BrandDetailModel(
      vehicles: VehicleModel.fromJsonList(json['vehicles']),
      nameBrand: json['name_brand'],
      banner: json['banner'],
      brandId: json['brand_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicles': vehicles.map((e) => e.toJson()).toList(),
      'name_brand': nameBrand,
      'banner': banner,
      'brand_id': brandId,
    };
  }
}
