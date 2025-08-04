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

    return MerekModel(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      slug: cast<String>(json['slug'], 'slug'),
      banner: cast<String?>(json['banner'], 'banner'),
      vehiclesCount: cast<int>(json['vehicles_count'], 'vehicles_count'),
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

  MerekModel copyWith({String? banner, int? vehiclesCount}) {
    return MerekModel(
      id: id,
      name: name,
      slug: slug,
      banner: banner ?? this.banner,
      vehiclesCount: vehiclesCount ?? this.vehiclesCount,
    );
  }
}
