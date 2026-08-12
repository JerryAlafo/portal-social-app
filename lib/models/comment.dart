import 'author.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String? parentId;
  final String content;
  final int likesCount;
  final bool? likedByMe;
  final String createdAt;
  final String? updatedAt;
  final Author? author;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentId,
    required this.content,
    this.likesCount = 0,
    this.likedByMe,
    required this.createdAt,
    this.updatedAt,
    this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] ?? '').toString(),
      postId: (json['post_id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      parentId: json['parent_id'] as String?,
      content: (json['content'] ?? '').toString(),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool?,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: json['updated_at'] as String?,
      author: json['author'] == null
          ? null
          : Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}

class EventComment {
  final String id;
  final String eventId;
  final String authorId;
  final String content;
  final String createdAt;
  final String? updatedAt;
  final Author? author;

  const EventComment({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.author,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) {
    return EventComment(
      id: (json['id'] ?? '').toString(),
      eventId: (json['event_id'] ?? '').toString(),
      authorId: (json['author_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: json['updated_at'] as String?,
      author: json['author'] == null
          ? null
          : Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}
