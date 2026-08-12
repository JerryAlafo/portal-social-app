import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  Future<ApiResult<List<Notification>>> getNotifications() async {
    try {
      final res = await ApiClient.instance.get('/api/notifications');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Notification.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar notificações.');
    }
  }

  Future<ApiResult<dynamic>> markAllAsRead() async {
    try {
      final res = await ApiClient.instance.patch('/api/notifications');
      if (res.statusCode >= 400) {
        return const ApiResult(error: 'Erro ao atualizar notificações.');
      }
      return const ApiResult(data: null);
    } catch (_) {
      return const ApiResult(error: 'Erro ao atualizar notificações.');
    }
  }
}
