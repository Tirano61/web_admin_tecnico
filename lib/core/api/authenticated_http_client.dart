import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';

class AuthenticatedHttpClient {
  AuthenticatedHttpClient({String? baseUrl})
      : baseUrl = baseUrl ?? configuredBaseUrl;

  static const String defaultBaseUrl =
      'https://backend-feedback-11c2.onrender.com/api/v1';
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  final String baseUrl;

  Uri buildUri(String endpoint, {Map<String, String>? queryParameters}) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$baseUrl$normalized');
    final cleanedQuery = <String, String>{
      for (final entry in (queryParameters ?? const <String, String>{}).entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value,
    };
    return uri.replace(queryParameters: cleanedQuery.isEmpty ? null : cleanedQuery);
  }

  Map<String, String> buildAuthHeaders() {
    final token = SessionStore.currentSession?.token;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    };
    return headers;
  }

  Future<dynamic> getJson(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = buildUri(endpoint, queryParameters: queryParameters);
    final response = await http.get(uri, headers: buildAuthHeaders());
    return _decodeResponse(response);
  }

  Future<dynamic> postJson(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = buildUri(endpoint, queryParameters: queryParameters);
    final response = await http.post(
      uri,
      headers: buildAuthHeaders(),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final status = response.statusCode;
    final rawBody = response.body.trim();

    dynamic payload;
    if (rawBody.isNotEmpty) {
      try {
        payload = jsonDecode(rawBody);
      } catch (_) {
        payload = rawBody;
      }
    }

    if (status >= 400) {
      final message = _extractErrorMessage(payload) ?? 'Error HTTP $status';
      throw AppFailure(message, statusCode: status);
    }

    return payload;
  }

  String? _extractErrorMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final message = payload['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
      final error = payload['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }
    return null;
  }
}
