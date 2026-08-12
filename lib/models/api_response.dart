import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado genérico das respostas da API ({ data, error }).
class ApiResult<T> {
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResult({this.data, this.error, this.statusCode = 200});

  bool get ok => error == null;
}

class ApiParser {
  /// Interpreta o wrapper { data, error } e converte com [fromJson].
  static ApiResult<T> parse<T>(
    http.Response res,
    T Function(dynamic json) fromJson, {
    T Function(dynamic json)? fromJsonList,
  }) {
    if (res.statusCode >= 400 && res.body.isEmpty) {
      return ApiResult(
        error: 'Erro (${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error != null) {
          return ApiResult(error: error.toString(), statusCode: res.statusCode);
        }
        final data = decoded['data'];
        if (data != null) {
          return ApiResult(data: fromJson(data), statusCode: res.statusCode);
        }
        // Respostas sem wrapper 'data' (ex: /api/auth/session).
        return ApiResult(data: fromJson(decoded), statusCode: res.statusCode);
      }
      // Respostas sem wrapper (ex: arrays no topo).
      return ApiResult(
        data: (fromJsonList ?? fromJson).call(decoded),
        statusCode: res.statusCode,
      );
    } catch (_) {
      return ApiResult(
        error: 'Resposta inválida do servidor.',
        statusCode: res.statusCode,
      );
    }
  }

  static String errorMessage(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err != null && err.toString().isNotEmpty) return err.toString();
      }
    } catch (_) {}
    return fallback;
  }
}
