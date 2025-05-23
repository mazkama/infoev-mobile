class FavoriteVehicle {
  final int id;
  final String name;
  final String slug;
  final String thumbnailUrl;
  final String brandName;

  FavoriteVehicle({
    required this.id,
    required this.name,
    required this.slug,
    required this.thumbnailUrl,
    required this.brandName,
  });

  factory FavoriteVehicle.fromJson(Map<String, dynamic> json) {
    return FavoriteVehicle(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      thumbnailUrl: json['thumbnail_url'] ?? '',
      brandName: json['brand']['name'] ?? '',
    );
  }
}
