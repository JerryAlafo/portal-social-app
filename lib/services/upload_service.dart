import '../core/api_client.dart';
import '../models/api_response.dart';

class UploadService {
  static final UploadService instance = UploadService._();
  UploadService._();

  Future<ApiResult<String>> uploadImage({
    required List<int> bytes,
    required String filename,
    String bucket = 'posts',
  }) async {
    try {
      final res = await ApiClient.instance.uploadFile(
        '/api/upload',
        fieldName: 'file',
        filename: filename,
        bytes: bytes,
        contentType: _contentTypeFor(filename),
        fields: {'bucket': bucket},
      );
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao fazer upload.'),
          statusCode: res.statusCode,
        );
      }
      return ApiParser.parse(res, (json) {
        final data = json as Map<String, dynamic>;
        return (data['url'] ?? '').toString();
      });
    } catch (_) {
      return const ApiResult(error: 'Erro ao fazer upload.');
    }
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
