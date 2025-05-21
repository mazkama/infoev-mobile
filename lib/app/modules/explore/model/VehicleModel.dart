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
    return VehicleModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      thumbnailUrl: json['thumbnail_url'],
      spec: json['spec'] != null ? SpecModel.fromJson(json['spec']) : null,
      brandId: json['brand_id'],
      typeId: json['type_id'],
      pictures: json['pictures'] != null
          ? List<PictureModel>.from(json['pictures'].map((x) => PictureModel.fromJson(x)))
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

  SpecModel({
    required this.specId,
    required this.value,
  });

  factory SpecModel.fromJson(Map<String, dynamic> json) {
    return SpecModel(
      specId: json['spec_id'],
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spec_id': specId,
      'value': value,
    };
  }
}

class PictureModel {
  final int id;
  final String path;
  final int thumbnail;

  PictureModel({
    required this.id,
    required this.path,
    required this.thumbnail,
  });

  factory PictureModel.fromJson(Map<String, dynamic> json) {
    return PictureModel(
      id: json['id'],
      path: json['path'],
      thumbnail: json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'thumbnail': thumbnail,
    };
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
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      banner: json['banner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'banner': banner,
    };
  }
}