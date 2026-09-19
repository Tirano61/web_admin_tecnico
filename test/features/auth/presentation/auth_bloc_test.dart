import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/roles_panel.dart';
import 'package:web_admin_tecnico/core/auth/session_expiration.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';
import 'package:web_admin_tecnico/features/auth/domain/validador_sesion_persistida.dart';
import 'package:web_admin_tecnico/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../support/jwt_de_prueba.dart';

void main() {
  setUp(SessionStore.clear);
  tearDown(SessionStore.clear);

  group('AuthBloc guard de rol', () {
    test('un admin-tecnico entra al panel', () async {
      final bloc = AuthBloc(_FakeAuthRepository(_sesion(<String>['admin-tecnico'])));

      bloc.add(AuthSubmitted(email: 'admin@empresa.com', password: 'Abc123'));
      final state = await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).session.roles, <String>['admin-tecnico']);
      await bloc.close();
    });

    test('un admin (superusuario) entra al panel', () async {
      final bloc = AuthBloc(_FakeAuthRepository(_sesion(<String>['admin'])));

      bloc.add(AuthSubmitted(email: 'root@empresa.com', password: 'Abc123'));
      final state = await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(state, isA<AuthAuthenticated>());
      await bloc.close();
    });

    test('un tecnico es rechazado con mensaje claro', () async {
      final bloc = AuthBloc(_FakeAuthRepository(_sesion(<String>['tecnico'])));

      bloc.add(AuthSubmitted(email: 'tecnico@empresa.com', password: 'Abc123'));
      final state = await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(state, isA<AuthAccesoDenegado>());
      expect((state as AuthFailureState).message, 'Este panel es solo para administración');
      expect(state.message, RolesPanel.mensajeAccesoDenegado);
      await bloc.close();
    });

    test('un tecnico rechazado no queda autenticado', () async {
      final bloc = AuthBloc(_FakeAuthRepository(_sesion(<String>['tecnico'])));

      bloc.add(AuthSubmitted(email: 'tecnico@empresa.com', password: 'Abc123'));
      await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(SessionStore.isAuthenticated, isFalse);
      await bloc.close();
    });

    test('un usuario sin roles es rechazado', () async {
      final bloc = AuthBloc(_FakeAuthRepository(_sesion(const <String>[])));

      bloc.add(AuthSubmitted(email: 'raro@empresa.com', password: 'Abc123'));
      final state = await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(state, isA<AuthAccesoDenegado>());
      await bloc.close();
    });
  });

  group('AuthBloc persistencia de sesion', () {
    test('el login guarda token y usuario en el storage', () async {
      final repository = _FakeAuthRepository(_sesion(<String>['admin-tecnico']));
      final bloc = AuthBloc(repository);

      bloc.add(AuthSubmitted(email: 'admin@empresa.com', password: 'Abc123'));
      await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(repository.guardada?.token, 'jwt');
      expect(repository.guardada?.email, 'usuario@empresa.com');
      expect(repository.guardada?.fullName, 'Juan Perez');
      expect(repository.guardada?.roles, <String>['admin-tecnico']);
      expect(SessionStore.isAuthenticated, isTrue);
      await bloc.close();
    });

    test('un tecnico rechazado no deja nada guardado', () async {
      final repository = _FakeAuthRepository(_sesion(<String>['tecnico']));
      final bloc = AuthBloc(repository);

      bloc.add(AuthSubmitted(email: 'tecnico@empresa.com', password: 'Abc123'));
      await bloc.stream.firstWhere((s) => s is! AuthLoading);

      expect(repository.guardada, isNull);
      await bloc.close();
    });

    test('el logout borra el storage y limpia SessionStore', () async {
      final repository = _FakeAuthRepository(_sesion(<String>['admin-tecnico']));
      final bloc = AuthBloc(repository);

      bloc.add(AuthSubmitted(email: 'admin@empresa.com', password: 'Abc123'));
      await bloc.stream.firstWhere((s) => s is AuthAuthenticated);

      bloc.add(AuthLogoutRequested());
      final state = await bloc.stream.firstWhere((s) => s is! AuthAuthenticated);

      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).mensaje, isNull);
      expect(repository.guardada, isNull);
      expect(SessionStore.isAuthenticated, isFalse);
      await bloc.close();
    });
  });

  group('AuthBloc restauracion al arrancar', () {
    test('restaura la sesion de un admin-tecnico y entra al panel', () async {
      final token = jwtDePrueba(roles: <String>['admin-tecnico']);
      final repository = _FakeAuthRepository(
        null,
        guardada: _sesion(<String>['admin-tecnico'], token: token),
      );
      final bloc = AuthBloc(repository);

      bloc.add(AuthSessionRestoreRequested());
      final estados = await bloc.stream.take(2).toList();

      expect(estados.first, isA<AuthRestoringSession>());
      expect(estados.last, isA<AuthAuthenticated>());
      expect(SessionStore.isAuthenticated, isTrue);
      expect(SessionStore.currentSession?.token, token);
      expect(SessionStore.puedeAccederAlPanel, isTrue);
      await bloc.close();
    });

    test('sin nada guardado manda al login sin mensaje', () async {
      final bloc = AuthBloc(_FakeAuthRepository(null));

      bloc.add(AuthSessionRestoreRequested());
      final state = await bloc.stream.firstWhere((s) => s is! AuthRestoringSession);

      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).mensaje, isNull);
      expect(SessionStore.isAuthenticated, isFalse);
      await bloc.close();
    });

    test('un token de tecnico guardado a mano no entra y se limpia', () async {
      final repository = _FakeAuthRepository(
        null,
        guardada: _sesion(<String>['tecnico'], token: jwtDePrueba(roles: <String>['tecnico'])),
      );
      final bloc = AuthBloc(repository);

      bloc.add(AuthSessionRestoreRequested());
      final state = await bloc.stream.firstWhere((s) => s is! AuthRestoringSession);

      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).mensaje, RolesPanel.mensajeAccesoDenegado);
      expect(repository.guardada, isNull);
      expect(SessionStore.isAuthenticated, isFalse);
      await bloc.close();
    });

    test('roles editados a mano no habilitan un token de tecnico', () async {
      final repository = _FakeAuthRepository(
        null,
        // El usuario guardado dice admin-tecnico, el token firmado dice tecnico.
        guardada: _sesion(<String>['admin-tecnico'], token: jwtDePrueba(roles: <String>['tecnico'])),
      );
      final bloc = AuthBloc(repository);

      bloc.add(AuthSessionRestoreRequested());
      final state = await bloc.stream.firstWhere((s) => s is! AuthRestoringSession);

      expect(state, isA<AuthUnauthenticated>());
      expect((state as AuthUnauthenticated).mensaje, RolesPanel.mensajeAccesoDenegado);
      expect(repository.guardada, isNull);
      await bloc.close();
    });

    test('un token vencido se limpia y avisa que la sesion expiro', () async {
      final repository = _FakeAuthRepository(
        null,
        guardada: _sesion(
          <String>['admin-tecnico'],
          token: jwtDePrueba(
            roles: <String>['admin-tecnico'],
            exp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ),
      );
      final bloc = AuthBloc(repository);

      bloc.add(AuthSessionRestoreRequested());
      final state = await bloc.stream.firstWhere((s) => s is! AuthRestoringSession);

      expect(state, isA<AuthUnauthenticated>());
      expect(
        (state as AuthUnauthenticated).mensaje,
        MotivoSesionInvalida.tokenVencido.mensaje,
      );
      expect(repository.guardada, isNull);
      expect(SessionStore.isAuthenticated, isFalse);
      await bloc.close();
    });
  });

  group('AuthBloc 401 del backend', () {
    test('cierra la sesion abierta y avisa', () async {
      final expiracion = SessionExpiration();
      final repository = _FakeAuthRepository(_sesion(<String>['admin-tecnico']));
      final bloc = AuthBloc(repository, sessionExpiration: expiracion);

      bloc.add(AuthSubmitted(email: 'admin@empresa.com', password: 'Abc123'));
      await bloc.stream.firstWhere((s) => s is AuthAuthenticated);

      expiracion.notificar();
      final state = await bloc.stream.firstWhere((s) => s is! AuthAuthenticated);

      expect(state, isA<AuthUnauthenticated>());
      expect(
        (state as AuthUnauthenticated).mensaje,
        MotivoSesionInvalida.tokenVencido.mensaje,
      );
      expect(repository.guardada, isNull);
      expect(SessionStore.isAuthenticated, isFalse);
      await bloc.close();
      await expiracion.dispose();
    });

    test('sin sesion abierta no hace nada', () async {
      final expiracion = SessionExpiration();
      final bloc = AuthBloc(_FakeAuthRepository(null), sessionExpiration: expiracion);

      expiracion.notificar();
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, isA<AuthInitial>());
      await bloc.close();
      await expiracion.dispose();
    });
  });

  group('SessionStore con roles', () {
    test('guarda los roles de la sesion', () {
      SessionStore.setSession(_sesion(<String>['admin-tecnico']));

      expect(SessionStore.isAuthenticated, isTrue);
      expect(SessionStore.rolesActuales, <String>['admin-tecnico']);
      expect(SessionStore.tieneRol('admin-tecnico'), isTrue);
      expect(SessionStore.tieneRol(RolesPanel.tecnico), isFalse);
      expect(SessionStore.puedeAccederAlPanel, isTrue);
      expect(SessionStore.currentSession?.token, 'jwt');
      expect(SessionStore.currentSession?.fullName, 'Juan Perez');
    });

    test('clear borra la sesion y sus roles', () {
      SessionStore.setSession(_sesion(<String>['admin']));
      SessionStore.clear();

      expect(SessionStore.isAuthenticated, isFalse);
      expect(SessionStore.rolesActuales, isEmpty);
      expect(SessionStore.puedeAccederAlPanel, isFalse);
    });
  });

  group('RolesPanel', () {
    test('normaliza mayusculas y guiones bajos', () {
      expect(RolesPanel.puedeAccederAlPanel(<String>['ADMIN_TECNICO']), isTrue);
      expect(RolesPanel.puedeAccederAlPanel(<String>[' Admin ']), isTrue);
      expect(RolesPanel.puedeAccederAlPanel(<String>['tecnico']), isFalse);
    });
  });
}

AuthSession _sesion(List<String> roles, {String token = 'jwt'}) => AuthSession(
      token: token,
      email: 'usuario@empresa.com',
      id: 'u-1',
      fullName: 'Juan Perez',
      roles: roles,
    );

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._loginSession, {AuthSession? guardada}) : _guardada = guardada;

  final AuthSession? _loginSession;
  AuthSession? _guardada;

  AuthSession? get guardada => _guardada;

  @override
  Future<AuthSession> login(LoginInput input) async {
    final session = _loginSession;
    if (session == null) {
      throw const AppFailure('Usuario o contrasena incorrectos', statusCode: 401);
    }
    return session;
  }

  @override
  Future<AuthSession?> sesionGuardada() async => _guardada;

  @override
  Future<void> guardarSesion(AuthSession session) async => _guardada = session;

  @override
  Future<void> logout() async => _guardada = null;
}
