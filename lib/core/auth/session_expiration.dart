import 'dart:async';

/// Canal unico para avisar que el backend rechazo el token (401).
///
/// `AuthenticatedHttpClient` lo notifica y el `AuthBloc` lo escucha, asi el
/// cierre de sesion por token vencido se decide en un solo lugar y no en cada
/// pantalla que hace requests.
class SessionExpiration {
  SessionExpiration();

  static final SessionExpiration instance = SessionExpiration();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get cambios => _controller.stream;

  void notificar() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  Future<void> dispose() => _controller.close();
}
