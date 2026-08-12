import 'author.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final String date;
  final String? location;
  final String? imageUrl;
  final String? organizerId;
  final int interestedCount;
  final int goingCount;
  final String? dateColor;
  final String createdAt;
  final Author? organizer;
  final bool? interestedByMe;
  final bool? goingByMe;
  final int? commentsCount;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.location,
    this.imageUrl,
    this.organizerId,
    this.interestedCount = 0,
    this.goingCount = 0,
    this.dateColor,
    required this.createdAt,
    this.organizer,
    this.interestedByMe,
    this.goingByMe,
    this.commentsCount,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description'] as String?,
      date: (json['date'] ?? '').toString(),
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      organizerId: json['organizer_id'] as String?,
      interestedCount: (json['interested_count'] as num?)?.toInt() ?? 0,
      goingCount: (json['going_count'] as num?)?.toInt() ?? 0,
      dateColor: json['date_color'] as String?,
      createdAt: (json['created_at'] ?? '').toString(),
      organizer: json['organizer'] == null
          ? null
          : Author.fromJson(json['organizer'] as Map<String, dynamic>),
      interestedByMe: json['interested_by_me'] as bool?,
      goingByMe: json['going_by_me'] as bool?,
      commentsCount: (json['comments_count'] as num?)?.toInt(),
    );
  }
}
