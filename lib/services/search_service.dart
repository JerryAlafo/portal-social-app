import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/trending_tag.dart';

class SearchResults {
  final List<Profile> users;
  final List<Post> posts;
  final List<TrendingTag> tags;

  const SearchResults({this.users = const [], this.posts = const [], this.tags = const []});
}

class SearchService {
  static final SearchService instance = SearchService._();
  SearchService._();

  Future<ApiResult<SearchResults>> search(
    String q, {
    String type = 'all',
  }) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/search',
        query: {'q': q, 'type': type},
      );
      return ApiParser.parse(res, (json) {
        final data = json as Map<String, dynamic>;
        return SearchResults(
          users: (data['users'] as List? ?? [])
              .map((e) => Profile.fromJson(e as Map<String, dynamic>))
              .toList(),
          posts: (data['posts'] as List? ?? [])
              .map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList(),
          tags: (data['tags'] as List? ?? [])
              .map((e) => TrendingTag.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao pesquisar.');
    }
  }
}
