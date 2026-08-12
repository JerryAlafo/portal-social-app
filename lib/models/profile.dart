class Profile {
  final String id;
  final String username;
  final String displayName;
  final String avatarInitials;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? website;
  final String role;
  final int level;
  final bool isOnline;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int likesReceivedCount;
  final String? createdAt;
  final bool? followedByMe;
  final bool? isFollowing;

  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarInitials,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.website,
    this.role = 'member',
    this.level = 1,
    this.isOnline = false,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.likesReceivedCount = 0,
    this.createdAt,
    this.followedByMe,
    this.isFollowing,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (json['display_name'] ?? '').toString(),
      avatarInitials: (json['avatar_initials'] ?? '').toString(),
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      website: json['website'] as String?,
      role: (json['role'] ?? 'member').toString(),
      level: (json['level'] as num?)?.toInt() ?? 1,
      isOnline: (json['is_online'] as bool?) ?? false,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      likesReceivedCount: (json['likes_received_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String?,
      followedByMe: json['followed_by_me'] as bool?,
      isFollowing: json['is_following'] as bool?,
    );
  }

  bool get isSuperUser => role == 'superuser';
  bool get isMod => role == 'mod' || role == 'superuser';
}
