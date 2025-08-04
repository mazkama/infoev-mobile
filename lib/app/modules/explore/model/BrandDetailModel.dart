import 'package:infoev/app/modules/explore/model/VehicleModel.dart';

T cast<T>(dynamic value, String fieldName) {
  if (value == null) return null as T;

  // Jika sudah tipe yang diinginkan, langsung return
  if (value is T) return value;

  // Handle int dari String/int
  if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString()))) {
    if (value is int) return value as T;
    final intValue = int.tryParse(value.toString());
    if (intValue != null) return intValue as T;
    if (T.toString().contains('?')) return null as T;
  }

  // Handle String dari int/String
  if ((T == String || RegExp(r'^String(\?|)$').hasMatch(T.toString()))) {
    return value.toString() as T;
  }

  // Fallback
  return value as T;
}

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
      nameBrand: cast<String>(json['name_brand'], 'name_brand'),
      banner: cast<String>(json['banner'], 'banner'),
      brandId: cast<int>(json['brand_id'], 'brand_id'),
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
