import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/comment.dart';

class CommentService {
  static final CommentService instance = CommentService._();
  CommentService._();

  Future<ApiResult<List<Comment>>> getComments(
    String postId, {
    bool includeReplies = true,
  }) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/comments/$postId',
        query: {'include_replies': '$includeReplies'},
      );
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Comment.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar comentários.');
    }
  }

  Future<ApiResult<Comment>> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/comments/$postId',
        body: {'content': content, 'parent_id': parentId},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao comentar.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Comment.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao comentar.');
    }
  }

  Future<ApiResult<Comment>> editComment(
    String postId,
    String commentId,
    String content,
  ) async {
    try {
      final res = await ApiClient.instance.patch(
        '/api/comments/$postId',
        body: {'comment_id': commentId, 'content': content},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao editar comentário.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Comment.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao editar comentário.');
    }
  }

  Future<ApiResult<dynamic>> deleteComment(String postId, String commentId) async {
    try {
      final res = await ApiClient.instance.delete(
        '/api/comments/$postId',
        body: {'comment_id': commentId},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao apagar comentário.'),
          statusCode: res.statusCode,
        );
      }
      return const ApiResult(data: null);
    } catch (_) {
      return const ApiResult(error: 'Erro ao apagar comentário.');
    }
  }

  Future<ApiResult<bool>> likeComment(String postId, String commentId) async {
    try {
      final res =
          await ApiClient.instance.post('/api/comments/$postId/$commentId/like');
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
}
