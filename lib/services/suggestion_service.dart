import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/profile.dart';
import '../models/trending_tag.dart';

class SuggestionService {
  static final SuggestionService instance = SuggestionService._();
  SuggestionService._();

  Future<ApiResult<List<Profile>>> getSuggestions() async {
    try {
      final res = await ApiClient.instance.get('/api/suggestions');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar sugestões.');
    }
  }

  Future<ApiResult<List<TrendingTag>>> getTrending() async {
    try {
      final res = await ApiClient.instance.get('/api/trending');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => TrendingTag.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar trending.');
    }
  }
}
