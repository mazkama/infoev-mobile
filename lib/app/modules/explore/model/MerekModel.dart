class MerekModel {
  final int id;
  final String name;
  final String slug;
  final String? banner;
  final int vehiclesCount;

  MerekModel({
    required this.id,
    required this.name,
    required this.slug,
    this.banner,
    this.vehiclesCount = 0,
  });

  factory MerekModel.fromJson(Map<String, dynamic> json) {
    return MerekModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      banner: json['banner'],
      vehiclesCount: json['vehicles_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'banner': banner,
      'vehicles_count': vehiclesCount,
    };
  }

  MerekModel copyWith({
    String? banner,
    int? vehiclesCount,
  }) {
    return MerekModel(
      id: id,
      name: name,
      slug: slug,
      banner: banner ?? this.banner,
      vehiclesCount: vehiclesCount ?? this.vehiclesCount,
    );
  }
}
