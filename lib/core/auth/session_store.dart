import 'package:web_admin_tecnico/core/auth/auth_session.dart';

class SessionStore {
  static AuthSession? _session;

  static AuthSession? get currentSession => _session;

  static bool get isAuthenticated => _session != null;

  static List<String> get rolesActuales => _session?.roles ?? const <String>[];

  static bool get puedeAccederAlPanel => _session?.puedeAccederAlPanel ?? false;

  static bool tieneRol(String rol) => _session?.tieneRol(rol) ?? false;

  static void setSession(AuthSession session) {
    _session = session;
  }

  static void clear() {
    _session = null;
  }
}
