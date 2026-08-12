import 'author.dart';

class Notification {
  final String id;
  final String userId;
  final String actorId;
  final String type;
  final String? postId;
  final String? eventId;
  final bool isRead;
  final String createdAt;
  final Author? actor;

  const Notification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.postId,
    this.eventId,
    this.isRead = false,
    required this.createdAt,
    this.actor,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      actorId: (json['actor_id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      postId: json['post_id'] as String?,
      eventId: json['event_id'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: (json['created_at'] ?? '').toString(),
      actor: json['actor'] == null
          ? null
          : Author.fromJson(json['actor'] as Map<String, dynamic>),
    );
  }
}
