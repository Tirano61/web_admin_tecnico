import 'dart:convert';

/// Lectura del payload de un JWT emitido por el backend.
///
/// El backend firma `{ id, roles }` con `expiresIn: 2h`, asi que el propio
/// token es la fuente confiable de identidad: lo que quedo guardado en el
/// navegador puede haber sido editado a mano, la firma del token no.
class JwtToken {
  const JwtToken._();

  /// Margen para no dar por valido un token que vence en los proximos segundos.
  static const Duration margenExpiracion = Duration(seconds: 30);

  static Map<String, dynamic> payload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
      return const <String, dynamic>{};
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  static bool esLegible(String token) => payload(token).isNotEmpty;

  static String? id(String token) {
    final valor = (payload(token)['id'] ?? payload(token)['sub'] ?? '').toString().trim();
    return valor.isEmpty || valor == 'null' ? null : valor;
  }

  /// Roles firmados dentro del token (`roles` array, o `role`/`rol` simple).
  static List<String> roles(String token) {
    final datos = payload(token);
    final crudo = datos['roles'] ?? datos['role'] ?? datos['rol'];

    if (crudo is List) {
      final roles = <String>[];
      for (final item in crudo) {
        final rol = item.toString().trim();
        if (rol.isNotEmpty && rol != 'null') {
          roles.add(rol);
        }
      }
      return roles;
    }

    final unico = (crudo ?? '').toString().trim();
    return unico.isEmpty || unico == 'null' ? const <String>[] : <String>[unico];
  }

  static DateTime? expiracion(String token) {
    final exp = payload(token)['exp'];
    if (exp is! num) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch((exp * 1000).round(), isUtc: true);
  }

  /// Un token sin `exp` legible no se considera vencido: en ese caso la ultima
  /// palabra la tiene el backend con un 401.
  static bool estaVencido(String token, {DateTime? ahora}) {
    final expiracionToken = expiracion(token);
    if (expiracionToken == null) {
      return false;
    }
    final momento = (ahora ?? DateTime.now()).toUtc();
    return !momento.isBefore(expiracionToken.subtract(margenExpiracion));
  }
}
