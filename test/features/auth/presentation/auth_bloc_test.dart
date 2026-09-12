import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/roles_panel.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';
import 'package:web_admin_tecnico/features/auth/presentation/bloc/auth_bloc.dart';

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

AuthSession _sesion(List<String> roles) => AuthSession(
      token: 'jwt',
      email: 'usuario@empresa.com',
      id: 'u-1',
      fullName: 'Juan Perez',
      roles: roles,
    );

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.session);

  final AuthSession session;

  @override
  Future<AuthSession> login(LoginInput input) async => session;

  @override
  Future<void> logout() async {}
}
