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
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      vehiclesCount: json['vehicles_count'],
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