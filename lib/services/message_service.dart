import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/conversation.dart';

class MessageService {
  static final MessageService instance = MessageService._();
  MessageService._();

  Future<ApiResult<List<Conversation>>> getConversations() async {
    try {
      final res = await ApiClient.instance.get('/api/conversations');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar conversas.');
    }
  }

  Future<ApiResult<List<Message>>> getMessages(String conversationId) async {
    try {
      final res = await ApiClient.instance.get('/api/conversations/$conversationId/messages');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar mensagens.');
    }
  }

  Future<ApiResult<Message>> sendMessage(String conversationId, String content) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/conversations/$conversationId/messages',
        body: {'content': content},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao enviar mensagem.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Message.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao enviar mensagem.');
    }
  }

  Future<ApiResult<String?>> getOrCreateConversation(String userId) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/conversations/get-or-create',
        query: {'user_id': userId},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao abrir conversa.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['id'] as String?);
    } catch (_) {
      return const ApiResult(error: 'Erro ao abrir conversa.');
    }
  }

  Future<ApiResult<dynamic>> markConversationRead(String conversationId) async {
    try {
      final res = await ApiClient.instance.patch(
        '/api/conversations/$conversationId/messages/read',
      );
      if (res.statusCode >= 400) {
        return const ApiResult(error: 'Erro ao marcar como lido.');
      }
      return const ApiResult(data: null);
    } catch (_) {
      return const ApiResult(error: 'Erro ao marcar como lido.');
    }
  }
}
