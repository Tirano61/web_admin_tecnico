import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<AuthSession> login(LoginInput input) async {
    final email = input.email.trim();
    final password = input.password.trim();

    if (email.isEmpty || password.isEmpty) {
      throw const AppFailure('Email y password son obligatorios', statusCode: 400);
    }

    final credentialBodies = <Map<String, dynamic>>[
      <String, dynamic>{'email': email, 'password': password},
      <String, dynamic>{'usuario': email, 'password': password},
      <String, dynamic>{'username': email, 'password': password},
      <String, dynamic>{'user': email, 'password': password},
      <String, dynamic>{'identifier': email, 'password': password},
    ];

    dynamic payload;
    AppFailure? lastFailure;

    for (final body in credentialBodies) {
      try {
        payload = await _httpClient.postJson(
          '/auth/login',
          includeAuth: false,
          body: body,
        );
        break;
      } on AppFailure catch (error) {
        if (error.statusCode == 400 || error.statusCode == 401) {
          lastFailure = error;
          continue;
        }
        rethrow;
      }
    }

    if (payload == null) {
      if (lastFailure != null && (lastFailure.statusCode == 400 || lastFailure.statusCode == 401)) {
        throw const AppFailure('Usuario o contrasena incorrectos', statusCode: 401);
      }
      throw lastFailure ?? const AppFailure('No fue posible autenticar usuario', statusCode: 401);
    }

    // Shape de POST /auth/login: { access_token, user: { id, fullName, email, roles } }
    final root = _asMap(payload);
    final data = _asMap(root['data']);
    final rootUser = _asMap(root['user']);
    final user = rootUser.isNotEmpty ? rootUser : _asMap(data['user']);

    final token = _stringOrNull(
      root['access_token'] ??
          root['accessToken'] ??
          data['access_token'] ??
          data['accessToken'],
    );

    if (token == null || token.isEmpty) {
      throw const AppFailure(
        'La respuesta de login no contiene access_token',
        statusCode: 500,
      );
    }

    final resolvedEmail = _stringOrNull(user['email'] ?? data['email'] ?? root['email']) ?? email;

    return AuthSession(
      token: token,
      email: resolvedEmail,
      id: _stringOrNull(user['id']),
      fullName: _stringOrNull(user['fullName'] ?? user['full_name']),
      roles: _rolesFrom(user['roles'] ?? user['role'] ?? user['rol']),
    );
  }

  @override
  Future<void> logout() async {}

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  List<String> _rolesFrom(dynamic value) {
    if (value is List) {
      final roles = <String>[];
      for (final item in value) {
        final rol = _stringOrNull(item);
        if (rol != null) {
          roles.add(rol);
        }
      }
      return roles;
    }

    final single = _stringOrNull(value);
    return single == null ? const <String>[] : <String>[single];
  }

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }
}
