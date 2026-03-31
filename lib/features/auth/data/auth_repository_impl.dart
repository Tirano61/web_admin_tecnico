import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<AuthSession> login(LoginInput input) async {
    final email = input.email.trim();
    final password = input.password.trim();

    if (email.isEmpty || password.isEmpty) {
      throw const AppFailure('Email y password son obligatorios', statusCode: 400);
    }

    return AuthSession(token: 'jwt-dev-token', email: email);
  }

  @override
  Future<void> logout() async {}
}
