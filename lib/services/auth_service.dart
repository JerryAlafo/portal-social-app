import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../models/api_response.dart';
import '../models/profile.dart';

enum AuthStatus { unknown, guest, authenticated }

/// Serviço de autenticação contra o NextAuth do servidor.
class AuthService extends ChangeNotifier {
  static const _guestKey = 'portal_guest';
  static const _sessionTokenKey = 'authjs.session-token';

  AuthStatus _status = AuthStatus.unknown;
  Profile? _profile;
  bool _booting = true;
  String? get _googleClientId => AppConfig.googleClientId;

  AuthStatus get status => _status;
  Profile? get profile => _profile;
  bool get isGuest => _status == AuthStatus.guest;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isBooting => _booting;

  void init() {
    ApiClient.instance.onAuthRequired = _handleAuthRequired;
  }

  Future<void> restoreSession() async {
    init();
    _booting = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_sessionTokenKey);
    final guest = prefs.getBool(_guestKey) ?? false;

    if (guest) {
      _status = AuthStatus.guest;
      _booting = false;
      notifyListeners();
      return;
    }

    if (token != null && token.isNotEmpty) {
      // Restaura o cookie de sessão para requisições autenticadas.
      ApiClient.instance.setSessionToken(token);
      final res = await _fetchSession();
      if (res.data != null) {
        _status = AuthStatus.authenticated;
        _profile = _profileFromSession(res.data!);
        _booting = false;
        notifyListeners();
        return;
      }
      await _clearSession();
    }

    _status = AuthStatus.unknown;
    _booting = false;
    notifyListeners();
  }

  /// Login com email/password via NextAuth.
  Future<ApiResult<Profile?>> login(String email, String password) async {
    try {
      debugPrint('LOGIN_START: email=$email');
      final csrf = await ApiClient.instance.fetchCsrfToken();
      if (csrf.isEmpty) {
        return const ApiResult(error: 'Não foi possível iniciar sessão.');
      }

      final res = await ApiClient.instance.post(
        '/api/auth/callback/credentials',
        form: {
          'csrfToken': csrf,
          'email': email,
          'password': password,
          'callbackUrl': 'https://portal-mz.vercel.app/feed',
          'json': 'true',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 302) {
        debugPrint('LOGIN_STATUS: ${res.statusCode}');
        debugPrint('LOGIN_BODY: ${res.body}');
        return ApiResult(
          error: _loginError(res.statusCode),
          statusCode: res.statusCode,
        );
      }

      final session = await _fetchSession();
      if (session.data == null) {
        debugPrint('LOGIN_SESSION_NULL: ${session.error}');
        return ApiResult(
          error: _redirectError(res),
          statusCode: res.statusCode,
        );
      }

      await _persistSession();
      _status = AuthStatus.authenticated;
      _profile = _profileFromSession(session.data!);
      _booting = false;
      notifyListeners();
      return const ApiResult(data: null);
    } catch (e) {
      debugPrint('LOGIN_EXCEPTION: $e');
      return const ApiResult(error: 'Erro de ligação ao servidor.');
    }
  }

  static bool _googleInitialized = false;

  Future<ApiResult<Profile?>> loginWithGoogle() async {
    try {
      final gs = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await gs.initialize(serverClientId: _googleClientId);
        _googleInitialized = true;
      }
      final account =
          await gs.authenticate(scopeHint: const ['email', 'profile']);
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return const ApiResult(error: 'Falha a obter token do Google.');
      }

      final csrf = await ApiClient.instance.fetchCsrfToken();
      final res = await ApiClient.instance.post(
        '/api/auth/callback/google',
        form: {
          'csrfToken': csrf,
          'id_token': idToken,
          'callbackUrl': 'https://portal-mz.vercel.app/feed',
          'json': 'true',
        },
      );

      if (res.statusCode != 200 && res.statusCode != 302) {
        return ApiResult(
          error: 'Não foi possível entrar com Google (${res.statusCode}).',
          statusCode: res.statusCode,
        );
      }

      final session = await _fetchSession();
      if (session.data == null) {
        return ApiResult(
          error: _googleRedirectError(res),
          statusCode: res.statusCode,
        );
      }

      await _persistSession();
      _status = AuthStatus.authenticated;
      _profile = _profileFromSession(session.data!);
      notifyListeners();
      return const ApiResult(data: null);
    } catch (e) {
      return ApiResult(error: 'Erro no login com Google: $e');
    }
  }

  Future<ApiResult<bool>> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final ban = await ApiClient.instance.post(
        '/api/auth/check-ban',
        body: {'email': email},
      );
      final banBody = jsonDecode(ban.body) as Map<String, dynamic>;
      if ((banBody['banned'] as bool?) ?? false) {
        return ApiResult(
          error: banBody['permanent'] == true
              ? 'Esta conta foi suspensa permanentemente.'
              : 'Esta conta está suspensa até ${_formatDate(banBody['expires_at'])}.',
        );
      }

      final res = await ApiClient.instance.post(
        '/api/auth/register',
        body: {
          'email': email,
          'password': password,
          'username': username.trim(),
          'display_name': displayName.trim(),
        },
      );

      if (res.statusCode != 201) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao criar conta.'),
          statusCode: res.statusCode,
        );
      }

      // Tenta login automático após o registo.
      final loginRes = await login(email, password);
      if (loginRes.ok) {
        return const ApiResult(data: true);
      }
      return const ApiResult(data: true);
    } catch (e) {
      return const ApiResult(error: 'Erro de ligação ao servidor.');
    }
  }

  /// Ativa o modo convidado.
  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
    ApiClient.instance.clearSessionToken();
    _status = AuthStatus.guest;
    _profile = null;
    notifyListeners();
  }

  /// Sai do modo convidado (mantém sessão anterior se existir).
  Future<void> exitGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    _status = AuthStatus.unknown;
    notifyListeners();
  }

  /// Atualiza o perfil local (ex.: após completar o onboarding).
  void applyProfile(Profile profile) {
    _profile = profile;
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSession();
    _status = AuthStatus.unknown;
    _profile = null;
    notifyListeners();
  }

  /// Elimina a conta do utilizador (DELETE /api/account).
  Future<ApiResult<bool>> deleteAccount() async {
    try {
      final res = await ApiClient.instance.delete('/api/account');
      if (res.statusCode >= 400) {
        return ApiResult(
          error: ApiParser.errorMessage(res, 'Erro ao eliminar conta.'),
          statusCode: res.statusCode,
        );
      }
      await _clearSession();
      return const ApiResult(data: true);
    } catch (_) {
      return const ApiResult(error: 'Erro de ligação ao servidor.');
    }
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = ApiClient.instance.sessionToken;
    if (cookie != null) {
      await prefs.setString(_sessionTokenKey, cookie);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
    ApiClient.instance.clearSessionToken();
  }

  Future<ApiResult<Map<String, dynamic>>> _fetchSession() async {
    try {
      final res = await ApiClient.instance.get('/api/auth/session');
      if (res.statusCode != 200 || res.body.isEmpty || res.body == 'null') {
        return const ApiResult(error: 'Sem sessão.');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ApiResult(data: data);
    } catch (e) {
      return const ApiResult(error: 'Erro a obter sessão.');
    }
  }

  Profile? _profileFromSession(Map<String, dynamic> session) {
    final user = session['user'];
    if (user is Map<String, dynamic> && user.isNotEmpty) {
      return Profile(
        id: (user['id'] ?? '').toString(),
        username: (user['username'] ?? '').toString(),
        displayName: (user['name'] ?? '').toString(),
        avatarInitials: (user['avatar_initials'] ?? '').toString(),
        avatarUrl: user['avatar_url'] as String?,
        role: (user['role'] ?? 'member').toString(),
      );
    }
    return null;
  }

  String _loginError(int status) {
    switch (status) {
      case 401:
        return 'Credenciais inválidas.';
      case 403:
        return 'Esta conta foi suspensa.';
      default:
        return 'Erro ao iniciar sessão.';
    }
  }

  /// Mapeia o erro do redirect do NextAuth (Location: ...?error=...).
  String _redirectError(http.Response res) {
    final uri = Uri.tryParse(res.headers['location'] ?? '');
    switch (uri?.queryParameters['error']) {
      case 'CredentialsSignin':
        return 'Credenciais inválidas.';
      case 'MissingCSRF':
        return 'Erro de segurança. Tenta novamente.';
      default:
        return 'Não foi possível iniciar sessão.';
    }
  }

  String _googleRedirectError(http.Response res) {
    final uri = Uri.tryParse(res.headers['location'] ?? '');
    switch (uri?.queryParameters['error']) {
      case 'OAuthSignin':
      case 'OAuthCallback':
      case 'AccessDenied':
        return 'Acesso negado pelo Google.';
      case 'MissingCSRF':
        return 'Erro de segurança. Tenta novamente.';
      default:
        return 'Sessão Google não confirmada.';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'data desconhecida';
    try {
      final dt = DateTime.parse(value.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  void _handleAuthRequired() {
    if (status != AuthStatus.guest) {
      _status = AuthStatus.unknown;
      _profile = null;
      notifyListeners();
    }
  }
}
