import 'author.dart';

class Fanfic {
  final String id;
  final String title;
  final String? synopsis;
  final String authorId;
  final String? fandom;
  final String? genre;
  final String language;
  final String? coverUrl;
  final String status;
  final int chapters;
  final int words;
  final int readsCount;
  final int likesCount;
  final String createdAt;
  final String updatedAt;
  final Author? author;

  const Fanfic({
    required this.id,
    required this.title,
    this.synopsis,
    required this.authorId,
    this.fandom,
    this.genre,
    this.language = 'pt',
    this.coverUrl,
    this.status = 'ongoing',
    this.chapters = 0,
    this.words = 0,
    this.readsCount = 0,
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  factory Fanfic.fromJson(Map<String, dynamic> json) {
    return Fanfic(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      synopsis: json['synopsis'] as String?,
      authorId: (json['author_id'] ?? '').toString(),
      fandom: json['fandom'] as String?,
      genre: json['genre'] as String?,
      language: (json['language'] ?? 'pt').toString(),
      coverUrl: json['cover_url'] as String?,
      status: (json['status'] ?? 'ongoing').toString(),
      chapters: (json['chapters'] as num?)?.toInt() ?? 0,
      words: (json['words'] as num?)?.toInt() ?? 0,
      readsCount: (json['reads_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      author: json['author'] == null
          ? null
          : Author.fromJson(json['author'] as Map<String, dynamic>),
    );
  }
}
