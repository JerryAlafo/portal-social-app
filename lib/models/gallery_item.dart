import 'author.dart';

class GalleryItem {
  final String id;
  final String authorId;
  final String? title;
  final String imageUrl;
  final String? category;
  final int likesCount;
  final String createdAt;
  final Author? author;

  const GalleryItem({
    required this.id,
    required this.authorId,
    this.title,
    required this.imageUrl,
    this.category,
    this.likesCount = 0,
    required this.createdAt,
    this.author,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: (json['id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      title: json['title'] as String?,
      imageUrl: (json['image_url'] ?? '').toString(),
      category: json['category'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      author: json['author'] == null
          ? null
          : Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}
