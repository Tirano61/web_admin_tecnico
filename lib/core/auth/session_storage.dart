import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';

/// Persistencia de la sesion entre recargas del navegador (F5).
abstract class SessionStorage {
  Future<AuthSession?> leer();

  Future<void> guardar(AuthSession session);

  Future<void> limpiar();
}

/// Implementacion sobre `flutter_secure_storage`.
///
/// En web guarda cifrado en `localStorage`, por eso la sesion sobrevive a un
/// F5 y al cierre de la pestana. Requiere https o localhost.
class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String tokenKey = 'web_admin_tecnico.access_token';
  static const String usuarioKey = 'web_admin_tecnico.usuario';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> leer() async {
    try {
      final token = (await _storage.read(key: tokenKey))?.trim();
      if (token == null || token.isEmpty) {
        return null;
      }

      final usuarioCrudo = await _storage.read(key: usuarioKey);
      final usuario = _decodificarUsuario(usuarioCrudo);

      return AuthSession.fromJson(<String, dynamic>{...usuario, 'token': token});
    } catch (_) {
      // Storage bloqueado o contenido corrupto: se trata como "sin sesion".
      return null;
    }
  }

  @override
  Future<void> guardar(AuthSession session) async {
    try {
      await _storage.write(key: tokenKey, value: session.token);
      await _storage.write(key: usuarioKey, value: jsonEncode(session.usuarioToJson()));
    } catch (_) {
      // Si el navegador no deja escribir, la sesion sigue viva en memoria.
    }
  }

  @override
  Future<void> limpiar() async {
    try {
      await _storage.delete(key: tokenKey);
      await _storage.delete(key: usuarioKey);
    } catch (_) {
      // Nada que hacer: igual se limpia SessionStore en memoria.
    }
  }

  Map<String, dynamic> _decodificarUsuario(String? crudo) {
    if (crudo == null || crudo.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final json = jsonDecode(crudo);
      if (json is Map<String, dynamic>) {
        return json;
      }
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
    } catch (_) {
      // Usuario ilegible: se restaura solo con lo que diga el token.
    }
    return const <String, dynamic>{};
  }
}
