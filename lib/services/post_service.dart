import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/post.dart';

class PostService {
  static final PostService instance = PostService._();
  PostService._();

  Future<ApiResult<List<Post>>> getFeed(
    int page,
    int limit, {
    String? category,
    String? filter,
  }) async {
    try {
      final res = await ApiClient.instance.get('/api/feed', query: {
        'page': '$page',
        'limit': '$limit',
        'filter': ?filter,
        if (category != null && category != 'Tudo' && filter == null)
          'category': category,
      });
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar feed.');
    }
  }

  Future<ApiResult<Post>> getPost(String id) async {
    try {
      final res = await ApiClient.instance.get('/api/posts/$id');
      return ApiParser.parse(res, (json) => Post.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar publicação.');
    }
  }

  Future<ApiResult<Post>> createPost({
    required String content,
    String? category,
    String? imageUrl,
    bool isSpoiler = false,
    bool isSensitive = false,
  }) async {
    try {
      final res = await ApiClient.instance.post('/api/feed', body: {
        'content': content,
        if (category != null && category.isNotEmpty) 'category': category,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        'is_spoiler': isSpoiler,
        'is_sensitive': isSensitive,
      });
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao criar publicação.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Post.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao criar publicação.');
    }
  }

  Future<ApiResult<dynamic>> deletePost(String id) async {
    try {
      final res = await ApiClient.instance.delete('/api/posts/$id');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao apagar publicação.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: null);
    } catch (_) {
      return const ApiResult(error: 'Erro ao apagar publicação.');
    }
  }

  Future<ApiResult<bool>> toggleLike(String postId) async {
    try {
      final res = await ApiClient.instance.post('/api/posts/$postId/like');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao gostar.'),
          statusCode: res.statusCode,
        );
      }
      final parsed = ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['liked'] as bool? ?? false);
      return parsed;
    } catch (_) {
      return const ApiResult(error: 'Erro ao gostar.');
    }
  }

  Future<ApiResult<Post>> repostPost(String postId, {String content = ''}) async {
    try {
      final res =
          await ApiClient.instance.post('/api/posts/$postId/repost', body: {'content': content});
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao repostar.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Post.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao repostar.');
    }
  }

  Future<ApiResult<dynamic>> reportPost(
    String postId, {
    required String reason,
    String? description,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/posts/$postId/report',
        body: {
          'reason': reason,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao denunciar.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: null);
    } catch (_) {
      return const ApiResult(error: 'Erro ao denunciar.');
    }
  }

  Future<ApiResult<String?>> sharePost(String postId) async {
    try {
      final res = await ApiClient.instance.post('/api/posts/$postId/share');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao partilhar.'),
          statusCode: res.statusCode,
        );
      }
      final parsed = ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['share_url'] as String?);
      return parsed;
    } catch (_) {
      return const ApiResult(error: 'Erro ao partilhar.');
    }
  }
}
