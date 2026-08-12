import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    final raw = dotenv.env['API_BASE_URL'] ?? 'https://portal-mz.vercel.app/';
    return raw.trim().replaceFirst(RegExp(r'/$'), '');
  }

  static String get apiBaseUrl => '$baseUrl/api';

  /// Web client ID do projeto Google usado pelo NextAuth do servidor
  /// (audience esperada no id_token do login Google).
  static String? get googleClientId {
    final raw = dotenv.env['GOOGLE_CLIENT_ID']?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }
}
