import '../core/api_client.dart';
import '../models/api_response.dart';
import '../models/profile.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._();
  ProfileService._();

  Future<ApiResult<Profile>> getMyProfile() async {
    try {
      final res = await ApiClient.instance.get('/api/profile');
      return ApiParser.parse(res, (json) => Profile.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao carregar perfil.');
    }
  }

  Future<ApiResult<Profile>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final res = await ApiClient.instance.patch('/api/profile', body: updates);
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao atualizar perfil.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) => Profile.fromJson(json as Map<String, dynamic>));
    } catch (_) {
      return const ApiResult(error: 'Erro ao atualizar perfil.');
    }
  }
}
