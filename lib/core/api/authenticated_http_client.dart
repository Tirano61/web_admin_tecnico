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
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> buildAuthHeaders() {
    final token = SessionStore.currentSession?.token;
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
