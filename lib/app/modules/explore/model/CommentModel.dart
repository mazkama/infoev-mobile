class Reply {
  final int id;
  final String name;
  final String comment;
  final String createdAt;

  Reply({
    required this.id,
    required this.name,
    required this.comment,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      name: json['name'] ?? 'Anonimus',
      comment: json['comment'] ?? '',
      createdAt: json['created_at'],
    );
  }
}

class Comment {
  final int id;
  final String name;
  final String comment;
  final String createdAt;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.name,
    required this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    var repliesJson = json['replies'] as List? ?? [];
    List<Reply> repliesList = repliesJson.map((e) => Reply.fromJson(e)).toList();

    return Comment(
      id: json['id'],
      name: json['name'] ?? 'Anonimus',
      comment: json['comment'] ?? '',
      createdAt: json['created_at'],
      replies: repliesList,
    );
  }
}
