import 'package:web_admin_tecnico/core/auth/auth_session.dart';

class SessionStore {
  static AuthSession? _session;

  static AuthSession? get currentSession => _session;

  static bool get isAuthenticated => _session != null;

  static void setSession(AuthSession session) {
    _session = session;
  }

  static void clear() {
    _session = null;
  }
}
