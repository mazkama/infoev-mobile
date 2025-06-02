class NewsModel {
  final int id;
  final String title;
  final String summary;
  final String content;
  final String slug;
  final int published;
  final int featured;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.slug,
    required this.published,
    required this.featured,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      content: json['content'],
      slug: json['slug'],
      published:
          json['published'] is int
              ? json['published']
              : int.tryParse(json['published'].toString()) ?? 0,
      featured:
          json['featured'] is int
              ? json['featured']
              : int.tryParse(json['featured'].toString()) ?? 0,
      thumbnailUrl: json['thumbnail_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // @override
  // String toString() {
  //   return 'NewsModel{id: $id, title: $title}';
  // }
}
