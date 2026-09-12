import 'package:web_admin_tecnico/core/auth/roles_panel.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.email,
    this.id,
    this.fullName,
    this.roles = const <String>[],
  });

  /// Access token JWT (`access_token` en la respuesta de POST /auth/login).
  final String token;
  final String email;
  final String? id;
  final String? fullName;
  final List<String> roles;

  bool get puedeAccederAlPanel => RolesPanel.puedeAccederAlPanel(roles);

  bool tieneRol(String rol) =>
      roles.map(RolesPanel.normalizar).contains(RolesPanel.normalizar(rol));
}
