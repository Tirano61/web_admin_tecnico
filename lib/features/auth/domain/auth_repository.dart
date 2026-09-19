import 'package:web_admin_tecnico/core/auth/auth_session.dart';

class LoginInput {
  const LoginInput({required this.email, required this.password});

  final String email;
  final String password;
}

abstract class AuthRepository {
  Future<AuthSession> login(LoginInput input);

  /// Sesion persistida en el navegador, sin validar. `null` si no hay.
  Future<AuthSession?> sesionGuardada();

  /// Persiste token y datos del usuario para sobrevivir a un F5.
  Future<void> guardarSesion(AuthSession session);

  /// Borra token y usuario del storage.
  Future<void> logout();
}
