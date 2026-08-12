import 'author.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final String createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class Conversation {
  final String id;
  final String createdAt;
  final Author? otherUser;
  final MessagePreview? lastMessage;
  final int unreadCount;

  const Conversation({
    required this.id,
    this.createdAt = '',
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: (json['id'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      otherUser: json['other_user'] == null
          ? null
          : Author.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] == null
          ? null
          : MessagePreview.fromJson(json['last_message'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MessagePreview {
  final String content;
  final String createdAt;
  final String senderId;

  const MessagePreview({
    required this.content,
    required this.createdAt,
    required this.senderId,
  });

  factory MessagePreview.fromJson(Map<String, dynamic> json) {
    return MessagePreview(
      content: (json['content'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
    );
  }
}
