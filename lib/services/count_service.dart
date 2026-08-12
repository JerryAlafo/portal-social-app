import '../core/api_client.dart';
import '../models/api_response.dart';

class Counts {
  final int unreadMessages;
  final int unreadNotifications;
  final int followingCount;
  final int totalPosts;

  const Counts({
    this.unreadMessages = 0,
    this.unreadNotifications = 0,
    this.followingCount = 0,
    this.totalPosts = 0,
  });

  factory Counts.fromJson(Map<String, dynamic> json) {
    return Counts(
      unreadMessages: (json['unreadMessages'] as num?)?.toInt() ?? 0,
      unreadNotifications: (json['unreadNotifications'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      totalPosts: (json['total_posts'] as num?)?.toInt() ?? 0,
    );
  }
}

class CountService {
  static final CountService instance = CountService._();
  CountService._();

  Future<ApiResult<Counts>> getCounts() async {
    try {
      final res = await ApiClient.instance.get('/api/counts');
      return ApiParser.parse(res, (json) => Counts.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar contagens.');
    }
  }
}
