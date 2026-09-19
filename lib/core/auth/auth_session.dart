import 'package:web_admin_tecnico/core/auth/roles_panel.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.email,
    this.id,
    this.fullName,
    this.roles = const <String>[],
  });

  /// Sesion tal como quedo guardada en el navegador.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: _texto(json['token'] ?? json['access_token']) ?? '',
      email: _texto(json['email']) ?? '',
      id: _texto(json['id']),
      fullName: _texto(json['fullName'] ?? json['full_name']),
      roles: _roles(json['roles']),
    );
  }

  /// Access token JWT (`access_token` en la respuesta de POST /auth/login).
  final String token;
  final String email;
  final String? id;
  final String? fullName;
  final List<String> roles;

  bool get puedeAccederAlPanel => RolesPanel.puedeAccederAlPanel(roles);

  bool tieneRol(String rol) =>
      roles.map(RolesPanel.normalizar).contains(RolesPanel.normalizar(rol));

  AuthSession copyWith({String? id, List<String>? roles}) {
    return AuthSession(
      token: token,
      email: email,
      id: id ?? this.id,
      fullName: fullName,
      roles: roles ?? this.roles,
    );
  }

  /// Datos del usuario, sin el token: se guardan en una clave aparte.
  Map<String, dynamic> usuarioToJson() => <String, dynamic>{
        'id': id,
        'fullName': fullName,
        'email': email,
        'roles': roles,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        ...usuarioToJson(),
        'token': token,
      };

  static String? _texto(dynamic value) {
    final texto = (value ?? '').toString().trim();
    if (texto.isEmpty || texto == 'null') {
      return null;
    }
    return texto;
  }

  static List<String> _roles(dynamic value) {
    if (value is! List) {
      final unico = _texto(value);
      return unico == null ? const <String>[] : <String>[unico];
    }

    final roles = <String>[];
    for (final item in value) {
      final rol = _texto(item);
      if (rol != null) {
        roles.add(rol);
      }
    }
    return roles;
  }
}
