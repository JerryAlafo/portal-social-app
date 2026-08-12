import 'dart:convert';

import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/post.dart';
import '../models/profile.dart';

/// Resultado do perfil por username (contém profile + dados por tab).
class UserProfileResult {
  final Profile profile;
  final List<dynamic> data;
  final int page;
  final int limit;
  final bool hasMore;

  const UserProfileResult({
    required this.profile,
    required this.data,
    this.page = 1,
    this.limit = 20,
    this.hasMore = false,
  });
}

class UserService {
  static final UserService instance = UserService._();
  UserService._();

  Future<ApiResult<Profile>> getUserProfile(String id) async {
    try {
      final res = await ApiClient.instance.get('/api/users/$id');
      return ApiParser.parse(res, (json) => Profile.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar perfil.');
    }
  }

  Future<ApiResult<UserProfileResult>> getByUsername(
    String username, {
    String tab = 'posts',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await ApiClient.instance.get(
        '/api/users/username/$username/profile',
        query: {'tab': tab, 'page': '$page', 'limit': '$limit'},
      );
      if (res.statusCode == 404) {
        return const ApiResult(error: 'Utilizador não encontrado.');
      }
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao carregar perfil.'),
          statusCode: res.statusCode,
        );
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final profile = Profile.fromJson(json['profile'] as Map<String, dynamic>);
      final rawData = (json['data'] as List?) ?? [];
      List<dynamic> data;
      if (tab == 'fanfics') {
        data = rawData;
      } else if (tab == 'gallery') {
        data = rawData;
      } else {
        data = rawData
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return ApiResult(
        data: UserProfileResult(
          profile: profile,
          data: data,
          page: (json['page'] as num?)?.toInt() ?? page,
          limit: (json['limit'] as num?)?.toInt() ?? limit,
          hasMore: (json['hasMore'] as bool?) ?? false,
        ),
      );
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar perfil.');
    }
  }
}
