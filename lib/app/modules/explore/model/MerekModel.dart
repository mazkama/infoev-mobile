import 'package:flutter/foundation.dart'; // TODO: Remove this import when debug prints are removed

class MerekModel {
  final int id;
  final String name;
  final String slug;
  final String? banner;
  final int vehiclesCount;
  final Map<String, int>? vehicleTypeCounts;

  MerekModel({
    required this.id,
    required this.name,
    required this.slug,
    this.banner,
    this.vehiclesCount = 0,
    this.vehicleTypeCounts,
  });

  factory MerekModel.fromJson(Map<String, dynamic> json) {
    // TODO: Remove debug prints later
    debugPrint('DEBUG: MerekModel.fromJson input: $json');
    
    T cast<T>(dynamic value, String fieldName) {
      if (value == null) return null as T;
      if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString())) &&
          (value is String || value is int)) {
        if (value is int) return value as T;
        final intValue = int.tryParse(value.toString());
        if (intValue != null) return intValue as T;
        if (T.toString().contains('?')) return null as T;
      }
      if ((T == String || RegExp(r'^String(\?|)$').hasMatch(T.toString())) &&
          (value is int || value is String)) {
        return value.toString() as T;
      }
      if (value is T) return value;
      return value as T;
    }

    final result = MerekModel(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      slug: cast<String>(json['name']?.toString().toLowerCase().replaceAll(' ', '-'), 'slug'),
      banner: cast<String?>(json['thumbnail_url'], 'thumbnail_url'),
      vehiclesCount: cast<int>(json['vehicles_count'], 'vehicles_count'),
      vehicleTypeCounts: json['vehicle_type_counts'] != null 
          ? Map<String, int>.from(json['vehicle_type_counts']) 
          : null,
    );
    
    debugPrint('DEBUG: MerekModel created: id=${result.id}, name=${result.name}, banner=${result.banner}, vehiclesCount=${result.vehiclesCount}');
    
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnail_url': banner,
      'vehicles_count': vehiclesCount,
      'vehicle_type_counts': vehicleTypeCounts,
    };
  }

  MerekModel copyWith({
    String? banner, 
    int? vehiclesCount, 
    Map<String, int>? vehicleTypeCounts,
  }) {
    return MerekModel(
      id: id,
      name: name,
      slug: slug,
      banner: banner ?? this.banner,
      vehiclesCount: vehiclesCount ?? this.vehiclesCount,
      vehicleTypeCounts: vehicleTypeCounts ?? this.vehicleTypeCounts,
    );
  }
}
