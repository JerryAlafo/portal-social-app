class Announcement {
  final String id;
  final String title;
  final String? content;
  final String status;
  final bool pinned;
  final String? createdAt;
  final String? authorUsername;

  Announcement({
    required this.id,
    required this.title,
    this.content,
    this.status = 'draft',
    this.pinned = false,
    this.createdAt,
    this.authorUsername,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString(),
        status: json['status']?.toString() ?? 'draft',
        pinned: json['pinned'] == true,
        createdAt: json['created_at']?.toString(),
        authorUsername: json['author']?['username']?.toString(),
      );
}
