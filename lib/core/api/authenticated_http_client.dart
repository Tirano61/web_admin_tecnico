import 'package:web_admin_tecnico/core/auth/session_store.dart';

class AuthenticatedHttpClient {
  AuthenticatedHttpClient({this.basePath = '/api/v1'});

  final String basePath;

  Uri buildUri(String endpoint, {Map<String, String>? queryParameters}) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri(
      path: '$basePath$normalized',
      queryParameters: queryParameters,
    );
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
