import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/roles_panel.dart';
import 'package:web_admin_tecnico/core/auth/session_expiration.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';
import 'package:web_admin_tecnico/features/auth/domain/validador_sesion_persistida.dart';

abstract class AuthEvent {}

class AuthSubmitted extends AuthEvent {
  AuthSubmitted({required this.email, required this.password});

  final String email;
  final String password;
}

/// Arranque de la app: lee la sesion persistida antes de elegir pantalla.
class AuthSessionRestoreRequested extends AuthEvent {}

/// El backend rechazo el token (401) mientras se usaba el panel.
class AuthSessionExpired extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

abstract class AuthState {}

class AuthInitial extends AuthState {}

/// Leyendo el storage: la UI muestra el splash.
class AuthRestoringSession extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.session);

  final AuthSession session;
}

/// Sin sesion activa: arranque sin token, logout, token vencido o 401.
class AuthUnauthenticated extends AuthState {
  AuthUnauthenticated({this.mensaje});

  /// Motivo para mostrar en el login, si hubo uno.
  final String? mensaje;
}

class AuthFailureState extends AuthState {
  AuthFailureState(this.message);

  final String message;
}

/// Credenciales validas pero sin rol para operar este panel (ej. `tecnico`).
class AuthAccesoDenegado extends AuthFailureState {
  AuthAccesoDenegado() : super(RolesPanel.mensajeAccesoDenegado);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._repository, {
    ValidadorSesionPersistida validador = const ValidadorSesionPersistida(),
    SessionExpiration? sessionExpiration,
  })  : _validador = validador,
        super(AuthInitial()) {
    on<AuthSubmitted>(_onSubmitted);
    on<AuthSessionRestoreRequested>(_onSessionRestoreRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthLogoutRequested>(_onLogoutRequested);

    _expiracion = (sessionExpiration ?? SessionExpiration.instance)
        .cambios
        .listen((_) => add(AuthSessionExpired()));
  }

  final AuthRepository _repository;
  final ValidadorSesionPersistida _validador;
  late final StreamSubscription<void> _expiracion;

  Future<void> _onSubmitted(AuthSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final session = await _repository.login(
        LoginInput(email: event.email, password: event.password),
      );

      if (!session.puedeAccederAlPanel) {
        emit(AuthAccesoDenegado());
        return;
      }

      await _repository.guardarSesion(session);
      SessionStore.setSession(session);
      emit(AuthAuthenticated(session));
    } on AppFailure catch (error) {
      emit(AuthFailureState(_messageForFailure(error)));
    } catch (error) {
      emit(AuthFailureState('No se pudo iniciar sesion. Reintenta en unos segundos.'));
    }
  }

  Future<void> _onSessionRestoreRequested(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthRestoringSession());

    AuthSession? guardada;
    try {
      guardada = await _repository.sesionGuardada();
    } catch (_) {
      guardada = null;
    }

    final resultado = _validador.validar(guardada);
    final session = resultado.session;

    if (session == null) {
      await _cerrarSesion();
      emit(AuthUnauthenticated(mensaje: resultado.motivo?.mensaje));
      return;
    }

    SessionStore.setSession(session);
    emit(AuthAuthenticated(session));
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) {
      return;
    }
    await _cerrarSesion();
    emit(AuthUnauthenticated(mensaje: MotivoSesionInvalida.tokenVencido.mensaje));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _cerrarSesion();
    emit(AuthUnauthenticated());
  }

  Future<void> _cerrarSesion() async {
    SessionStore.clear();
    try {
      await _repository.logout();
    } catch (_) {
      // El storage puede fallar; en memoria la sesion ya quedo limpia.
    }
  }

  String _messageForFailure(AppFailure failure) {
    final statusCode = failure.statusCode;
    if (statusCode == 400 || statusCode == 401) {
      return 'Usuario o contrasena incorrectos';
    }

    final message = failure.message.trim();
    if (message.isEmpty) {
      return 'No se pudo iniciar sesion. Reintenta en unos segundos.';
    }

    return message;
  }

  @override
  Future<void> close() {
    _expiracion.cancel();
    return super.close();
  }
}
