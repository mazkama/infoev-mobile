T cast<T>(dynamic value, String fieldName) {
  if (value == null) return null as T;

  // Handle int and int? from String or int (universal)
  if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString())) && (value is String || value is int)) {
    if (value is int) return value as T;
    final intValue = int.tryParse(value.toString());
    if (intValue != null) return intValue as T;
    if (T.toString().contains('?')) return null as T;
  }

  // Handle String and String? from int or String
  if ((T == String || RegExp(r'^String(\?|)$').hasMatch(T.toString())) && (value is int || value is String)) {
    return value.toString() as T;
  }

  if (value is T) return value;

  // print('Warning: field "$fieldName" expected $T but got ${value.runtimeType}');
  return value as T;
}

class VehicleTypeModel {
  final int id;
  final String name;
  final String slug;
  final String createdAt;
  final String updatedAt;
  final int vehiclesCount;

  VehicleTypeModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
    required this.vehiclesCount,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      slug: cast<String>(json['slug'], 'slug'),
      createdAt: cast<String>(json['created_at'], 'created_at'),
      updatedAt: cast<String>(json['updated_at'], 'updated_at'),
      vehiclesCount: cast<int>(json['vehicles_count'], 'vehicles_count'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'vehicles_count': vehiclesCount,
    };
  }

  static List<VehicleTypeModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => VehicleTypeModel.fromJson(json)).toList();
  }
}
