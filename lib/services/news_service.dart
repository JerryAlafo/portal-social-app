import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/news_item.dart';

class NewsService {
  static final NewsService instance = NewsService._();
  NewsService._();

  Future<ApiResult<List<NewsItem>>> getNews({String? category}) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/news',
        query: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar notícias.');
    }
  }
}
