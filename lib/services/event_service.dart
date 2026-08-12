import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/comment.dart';
import '../models/event.dart';

class EventService {
  static final EventService instance = EventService._();
  EventService._();

  Future<ApiResult<List<Event>>> getEvents() async {
    try {
      final res = await ApiClient.instance.get('/api/events');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar eventos.');
    }
  }

  Future<ApiResult<Event>> getEvent(String id) async {
    try {
      final res = await ApiClient.instance.get('/api/events/$id');
      return ApiParser.parse(res, (json) => Event.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar evento.');
    }
  }

  Future<ApiResult<String?>> toggleInterest(String id, String type) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/events/$id/interest',
        body: {'type': type},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao atualizar interesse.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['type'] as String?);
    } catch (_) {
      return const ApiResult(error: 'Erro ao atualizar interesse.');
    }
  }

  Future<ApiResult<List<EventComment>>> getComments(String id) async {
    try {
      final res = await ApiClient.instance.get('/api/events/$id/comments');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => EventComment.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar comentários.');
    }
  }

  Future<ApiResult<EventComment>> addComment(String id, String content) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/events/$id/comments',
        body: {'content': content},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao comentar.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => EventComment.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao comentar.');
    }
  }

  Future<ApiResult<dynamic>> deleteComment(String id, String commentId) async {
    try {
      final res = await ApiClient.instance.delete(
        '/api/events/$id/comments',
        body: {'comment_id': commentId},
      );
      if (res.statusCode >= 400) {
        return const ApiResult(error: 'Erro ao apagar comentário.');
      }
      return const ApiResult(data: null);
    } catch (_) {
      return const ApiResult(error: 'Erro ao apagar comentário.');
    }
  }
}
