class TrendingTag {
  final String id;
  final String tag;
  final int postCount;

  const TrendingTag({
    required this.id,
    required this.tag,
    this.postCount = 0,
  });

  factory TrendingTag.fromJson(Map<String, dynamic> json) {
    return TrendingTag(
      id: (json['id'] ?? '').toString(),
      tag: (json['tag'] ?? '').toString(),
      postCount: (json['post_count'] as num?)?.toInt() ?? 0,
    );
  }
}
