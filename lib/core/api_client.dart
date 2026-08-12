import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import 'config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Cliente HTTP com gestão manual de cookies de sessão (NextAuth).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 45);

  final Map<String, String> _cookies = {};
  String? _csrfToken;

  /// Chamado quando a API responde 401 (sessão expirada / convidado).
  void Function()? onAuthRequired;

  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  /// Nomes das cookies de sessão do NextAuth (produção usa prefixos).
  static const _sessionCookieNames = [
    '__Secure-authjs.session-token',
    'authjs.session-token',
  ];

  /// Nomes das cookies de CSRF que o servidor pode usar.
  static const _csrfCookieNames = [
    '__Host-authjs.csrf-token',
    '__Secure-authjs.csrf-token',
    'authjs.csrf-token',
  ];

  /// Valor da cookie de sessão do NextAuth (se existir).
  String? get sessionToken {
    for (final name in _sessionCookieNames) {
      final value = _cookies[name];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  void setSessionToken(String token) {
    for (final name in _sessionCookieNames) {
      _cookies[name] = token;
    }
  }

  void clearSessionToken() {
    for (final name in _sessionCookieNames) {
      _cookies.remove(name);
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final full = path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';
    return Uri.parse(full).replace(queryParameters: query);
  }

  void _captureCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null) return;

    // O pacote http junta múltiplos Set-Cookie com ", ". Cada cookie tem a
    // forma "nome=valor" e os valores do Auth.js vêm URL-encoded.
    final cookieRe = RegExp('(?:^|,)\\s*([^;,]+)=([^;,]*)');
    for (final m in cookieRe.allMatches(setCookie)) {
      final name = m.group(1)!.trim();
      final value = m.group(2)!;
      _applyCookie(name, value);
    }
  }

  void _applyCookie(String name, String value) {
    final isSession = _sessionCookieNames
        .any((n) => name == n || name.startsWith('$n.'));
    final isCsrf = _csrfCookieNames.contains(name);
    if (!isSession && !isCsrf) return;

    if (value.isEmpty || value == 'deleted') {
      _cookies.remove(name);
    } else {
      _cookies[name] = value;
    }
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (_cookies.isNotEmpty) {
      headers['Cookie'] =
          _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    if (json) headers['Content-Type'] = 'application/json';
    return headers;
  }

  String get csrfToken => _csrfToken ?? '';

  /// Obtém o token CSRF do NextAuth (obrigatório para login).
  Future<String> fetchCsrfToken() async {
    final res = await http
        .get(_uri('/api/auth/csrf'), headers: _headers())
        .timeout(_timeout);
    _captureCookies(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    _csrfToken = body['csrfToken'] as String? ?? '';
    return _csrfToken ?? '';
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    final res = await http.get(_uri(path, query), headers: _headers()).timeout(_timeout);
    _captureCookies(res);
    _handle(res);
    return res;
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? form,
    Map<String, String>? query,
  }) async {
    final req = http.Request('POST', _uri(path, query));
    if (form != null) {
      req.headers.addAll(_headers());
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      req.body = _encodeForm(form);
    } else if (body != null) {
      req.headers.addAll(_headers(json: true));
      req.body = jsonEncode(body);
    } else {
      req.headers.addAll(_headers());
    }
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    _captureCookies(res);
    _handle(res);
    return res;
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final req = http.Request('PATCH', _uri(path, query));
    req.headers.addAll(_headers(json: true));
    req.body = body == null ? '' : jsonEncode(body);
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    _captureCookies(res);
    _handle(res);
    return res;
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final req = http.Request('PUT', _uri(path, query));
    req.headers.addAll(_headers(json: true));
    req.body = body == null ? '' : jsonEncode(body);
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    _captureCookies(res);
    _handle(res);
    return res;
  }

  Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final req = http.Request('DELETE', _uri(path, query));
    if (body != null) {
      req.headers.addAll(_headers(json: true));
      req.body = jsonEncode(body);
    } else {
      req.headers.addAll(_headers());
    }
    final streamed = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    _captureCookies(res);
    _handle(res);
    return res;
  }

  /// Envia um ficheiro como multipart/form-data para o endpoint de upload.
  Future<http.Response> uploadFile(
    String path, {
    required String fieldName,
    required String filename,
    required List<int> bytes,
    String? contentType,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (_cookies.isNotEmpty) {
      request.headers['Cookie'] =
          _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    if (fields != null) {
      fields.forEach((k, v) => request.fields[k] = v);
    }
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: filename,
      contentType:
          contentType == null ? null : http_parser.MediaType.parse(contentType),
    ));
    final streamed = await request.send().timeout(_timeout);
    final res = await http.Response.fromStream(streamed);
    _captureCookies(res);
    _handle(res);
    return res;
  }

  String _encodeForm(Map<String, String> data) {
    return data.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  void _handle(http.Response res) {
    if (res.statusCode == 401) {
      onAuthRequired?.call();
    }
  }
}
