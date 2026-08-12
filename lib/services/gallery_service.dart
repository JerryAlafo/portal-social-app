import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/gallery_item.dart';

class GalleryService {
  static final GalleryService instance = GalleryService._();
  GalleryService._();

  Future<ApiResult<List<GalleryItem>>> getGallery({String? category}) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/gallery',
        query: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => GalleryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar galeria.');
    }
  }

  Future<ApiResult<List<String>>> getLikedIds() async {
    try {
      final res = await ApiClient.instance.get('/api/gallery/likes');
      return ApiParser.parse(res, (json) {
        return (json as List? ?? [])
            .map((e) => (e as Map<String, dynamic>)['item_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar gostos.');
    }
  }

  Future<ApiResult<int>> toggleLike(String itemId) async {
    try {
      final res = await ApiClient.instance.patch(
        '/api/gallery',
        body: {'id': itemId, 'action': 'like'},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao gostar.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(
        res,
        (json) => ((json as Map<String, dynamic>)['likes_count'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const ApiResult(error: 'Erro ao gostar.');
    }
  }

  Future<ApiResult<GalleryItem>> uploadGalleryItem({
    required String title,
    required String category,
    required String imageUrl,
  }) async {
    try {
      final res = await ApiClient.instance.post(
        '/api/gallery',
        body: {
          'title': title,
          'category': category,
          'image_url': imageUrl,
        },
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao publicar na galeria.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => GalleryItem.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao publicar na galeria.');
    }
  }
}
