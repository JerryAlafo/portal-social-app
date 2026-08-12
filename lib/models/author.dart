/// Subconjunto do perfil usado em posts, comentários, etc.
class Author {
  final String id;
  final String username;
  final String displayName;
  final String avatarInitials;
  final String? avatarUrl;
  final String? role;
  final bool? isOnline;

  const Author({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarInitials,
    this.avatarUrl,
    this.role,
    this.isOnline,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      avatarInitials: (json['avatar_initials'] ?? '').toString(),
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      isOnline: json['is_online'] as bool?,
    );
  }
}
