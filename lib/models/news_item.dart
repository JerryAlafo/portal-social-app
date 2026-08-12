class NewsItem {
  final String id;
  final String title;
  final String? summary;
  final String? imageUrl;
  final String? category;
  final String? source;
  final String? publishedAt;

  const NewsItem({
    required this.id,
    required this.title,
    this.summary,
    this.imageUrl,
    this.category,
    this.source,
    this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: json['summary'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      source: json['source'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }
}
