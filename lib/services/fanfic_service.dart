import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/fanfic.dart';

class FanficService {
  static final FanficService instance = FanficService._();
  FanficService._();

  Future<ApiResult<List<Fanfic>>> getFanfics({
    String? fandom,
    String? sort,
  }) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/fanfics',
        query: {
          if (fandom != null && fandom.isNotEmpty) 'fandom': fandom,
          'sort': ?sort,
        },
      );
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Fanfic.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar fanfics.');
    }
  }

  Future<ApiResult<bool>> toggleLike(String fanficId) async {
    try {
      final res = await ApiClient.instance.post('/api/fanfics/$fanficId/like');
      if (res.statusCode >= 400) {
        return const ApiResult(error: 'Erro ao gostar.');
      }
      return ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['liked'] as bool? ?? false);
    } catch (_) {
      return const ApiResult(error: 'Erro ao gostar.');
    }
  }

  Future<ApiResult<Fanfic>> createFanfic({
    required String title,
    required String summary,
    required String fandom,
    required String genre,
    String status = 'Em curso',
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/fanfics',
        body: {
          'title': title,
          'summary': summary,
          'fandom': fandom,
          'genre': genre,
          'status': status,
        },
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao publicar fanfic.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Fanfic.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao publicar fanfic.');
    }
  }
}
