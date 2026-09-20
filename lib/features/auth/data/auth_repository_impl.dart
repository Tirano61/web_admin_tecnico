import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/auth/session_storage.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    AuthenticatedHttpClient? httpClient,
    SessionStorage? sessionStorage,
  })  : _httpClient = httpClient ?? AuthenticatedHttpClient(),
        _sessionStorage = sessionStorage ?? SecureSessionStorage();

  final AuthenticatedHttpClient _httpClient;
  final SessionStorage _sessionStorage;

  @override
  Future<AuthSession> login(LoginInput input) async {
    final email = input.email.trim();
    final password = input.password.trim();

    if (email.isEmpty || password.isEmpty) {
      throw const AppFailure('Email y password son obligatorios', statusCode: 400);
    }

    // Shape de POST /auth/login (LoginUserDto): { email, password }.
    final dynamic payload;
    try {
      payload = await _httpClient.postJson(
        '/auth/login',
        includeAuth: false,
        body: <String, dynamic>{'email': email, 'password': password},
      );
    } on AppFailure catch (error) {
      if (error.statusCode == 401) {
        throw const AppFailure('Usuario o contrasena incorrectos', statusCode: 401);
      }
      rethrow;
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
  Future<AuthSession?> sesionGuardada() => _sessionStorage.leer();

  @override
  Future<void> guardarSesion(AuthSession session) => _sessionStorage.guardar(session);

  @override
  Future<void> logout() => _sessionStorage.limpiar();

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
