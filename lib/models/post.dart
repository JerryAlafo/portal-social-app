import 'author.dart';

class Post {
  final String id;
  final String authorId;
  final String content;
  final String? category;
  final String? imageUrl;
  final bool? isSpoiler;
  final bool? isSensitive;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final String createdAt;
  final String updatedAt;
  final Author? author;
  final String? repostOfId;
  final Post? repost;
  final bool? likedByMe;
  final bool? followedByMe;

  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.category,
    this.imageUrl,
    this.isSpoiler,
    this.isSensitive,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.repostOfId,
    this.repost,
    this.likedByMe,
    this.followedByMe,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      category: json['category'] as String?,
      imageUrl: json['image_url'] as String?,
      isSpoiler: json['is_spoiler'] as bool?,
      isSensitive: json['is_sensitive'] as bool?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      author: json['author'] == null
          ? null
          : Author.fromJson(json['author'] as Map<String, dynamic>),
      repostOfId: json['repost_of_id'] as String?,
      repost: json['repost'] == null
          ? null
          : Post.fromJson(json['repost'] as Map<String, dynamic>),
      likedByMe: json['liked_by_me'] as bool?,
      followedByMe: json['followed_by_me'] as bool?,
    );
  }

  Post copyWith({
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? likedByMe,
    bool? followedByMe,
    String? content,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      content: content ?? this.content,
      category: category,
      imageUrl: imageUrl,
      isSpoiler: isSpoiler,
      isSensitive: isSensitive,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      repostOfId: repostOfId,
      repost: repost,
      likedByMe: likedByMe ?? this.likedByMe,
      followedByMe: followedByMe ?? this.followedByMe,
    );
  }
}
