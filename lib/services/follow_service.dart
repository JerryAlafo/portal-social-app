import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/profile.dart';

class FollowService {
  static final FollowService instance = FollowService._();
  FollowService._();

  Future<ApiResult<List<Profile>>> getFollowing() async {
    try {
      final res = await ApiClient.instance.get('/api/following');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar seguidos.');
    }
  }

  Future<ApiResult<bool>> checkFollowing(String userId) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/following',
        query: {'check': userId},
      );
      return ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['following'] as bool? ?? false);
    } catch (_) {
      return const ApiResult(error: 'Erro ao verificar seguimento.');
    }
  }

  Future<ApiResult<bool>> toggleFollow(String userId) async {
    try {
      final res = await ApiClient.instance.post('/api/following', body: {'user_id': userId});
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao seguir.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(
          res, (json) => (json as Map<String, dynamic>)['following'] as bool? ?? false);
    } catch (_) {
      return const ApiResult(error: 'Erro ao seguir.');
    }
  }

  Future<ApiResult<List<Profile>>> getFollowers(String userId) async {
    try {
      final res = await ApiClient.instance.get('/api/users/$userId/followers');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar seguidores.');
    }
  }

  Future<ApiResult<List<Profile>>> getFollowingList(String userId) async {
    try {
      final res = await ApiClient.instance.get('/api/users/$userId/following');
      return ApiParser.parse(res, (json) {
        return (json as List)
            .map((e) => Profile.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar seguidos.');
    }
  }
}
