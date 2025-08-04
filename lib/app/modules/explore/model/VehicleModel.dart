T cast<T>(dynamic value, String fieldName) {
  // print('DEBUG cast: $fieldName, value=$value, T=$T, value.runtimeType=${value?.runtimeType}');
  if (value == null) return null as T;

  // Handle int and int? from String or int (universal)
  if ((T == int || RegExp(r'^int(\?|)$').hasMatch(T.toString())) && (value is String || value is int)) {
    if (value is int) return value as T;
    final intValue = int.tryParse(value.toString());
    if (intValue != null) return intValue as T;
    // fallback for int? if cannot parse
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

class VehicleModel {
  final int id;
  final String name;
  final String slug;
  final String thumbnailUrl;
  final SpecModel? spec;
  final int? brandId;
  final int? typeId;
  final List<PictureModel>? pictures;
  final BrandModel? brand;

  VehicleModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.thumbnailUrl,
    this.spec,
    this.brandId,
    this.typeId,
    this.pictures,
    this.brand,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    // print('DEBUG VehicleModel.fromJson: $json');
    return VehicleModel(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'] ?? '', 'name'),
      slug: cast<String>(json['slug'] ?? '', 'slug'),
      thumbnailUrl: cast<String>(json['thumbnail_url'] ?? '', 'thumbnail_url'),
      spec: json['spec'] != null ? SpecModel.fromJson(json['spec']) : null,
      brandId: cast<int?>(json['brand_id'], 'brand_id'),
      typeId: cast<int?>(json['type_id'], 'type_id'),
      pictures: json['pictures'] != null
          ? List<PictureModel>.from(
              (json['pictures'] as List).map((x) => PictureModel.fromJson(x)),
            )
          : null,
      brand: json['brand'] != null ? BrandModel.fromJson(json['brand']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'thumbnail_url': thumbnailUrl,
      'spec': spec?.toJson(),
      'brand_id': brandId,
      'type_id': typeId,
      'pictures': pictures?.map((e) => e.toJson()).toList(),
      'brand': brand?.toJson(),
    };
  }

  static List<VehicleModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => VehicleModel.fromJson(json)).toList();
  }
}

class SpecModel {
  final int specId;
  final String value;

  SpecModel({required this.specId, required this.value});

  factory SpecModel.fromJson(Map<String, dynamic> json) {
    return SpecModel(
      specId: cast<int>(json['spec_id'], 'spec_id'),
      value: cast<String>(json['value'], 'value'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'spec_id': specId, 'value': value};
  }
}

class PictureModel {
  final int id;
  final String path;
  final int thumbnail;

  PictureModel({required this.id, required this.path, required this.thumbnail});

  factory PictureModel.fromJson(Map<String, dynamic> json) {
    return PictureModel(
      id: cast<int>(json['id'], 'id'),
      path: cast<String>(json['path'], 'path'),
      thumbnail: cast<int>(json['thumbnail'], 'thumbnail'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'path': path, 'thumbnail': thumbnail};
  }
}

class BrandModel {
  final int id;
  final String name;
  final String slug;
  final String? banner;

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.banner,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: cast<int>(json['id'], 'id'),
      name: cast<String>(json['name'], 'name'),
      slug: cast<String>(json['slug'], 'slug'),
      banner: cast<String?>(json['banner'], 'banner'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'slug': slug, 'banner': banner};
  }
}
