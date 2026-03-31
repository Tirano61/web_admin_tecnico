import 'package:web_admin_tecnico/core/auth/auth_session.dart';

class LoginInput {
  const LoginInput({required this.email, required this.password});

  final String email;
  final String password;
}

abstract class AuthRepository {
  Future<AuthSession> login(LoginInput input);

  Future<void> logout();
}
