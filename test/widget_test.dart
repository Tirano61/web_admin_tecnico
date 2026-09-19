import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/session_store.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';
import 'package:web_admin_tecnico/main.dart';

import 'support/jwt_de_prueba.dart';

void main() {
  tearDown(SessionStore.clear);

  testWidgets('arranca mostrando el splash mientras lee la sesion guardada',
      (WidgetTester tester) async {
    await tester.pumpWidget(WebAdminTecnicoApp(authRepository: _FakeAuthRepository()));

    expect(find.text('Restaurando sesion...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    await tester.pump();
  });

  testWidgets('sin sesion guardada muestra el login', (WidgetTester tester) async {
    await tester.pumpWidget(WebAdminTecnicoApp(authRepository: _FakeAuthRepository()));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.memory_rounded), findsOneWidget);
    expect(find.text('>- TERMINAL SEGURA'), findsOneWidget);
    expect(find.text('Acceso Interno'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(SessionStore.isAuthenticated, isFalse);
  });

  testWidgets('con sesion guardada valida entra directo al panel (F5)',
      (WidgetTester tester) async {
    final repository = _FakeAuthRepository(guardada: _sesionAdmin());

    await tester.pumpWidget(WebAdminTecnicoApp(authRepository: repository));
    await tester.pump();
    await tester.pump();

    expect(find.text('Acceso Interno'), findsNothing);
    expect(find.text('Servicios'), findsWidgets);
    expect(SessionStore.isAuthenticated, isTrue);
    expect(SessionStore.puedeAccederAlPanel, isTrue);
  });

  testWidgets('el boton de salir cierra la sesion y vuelve al login',
      (WidgetTester tester) async {
    final repository = _FakeAuthRepository(guardada: _sesionAdmin());

    await tester.pumpWidget(WebAdminTecnicoApp(authRepository: repository));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Acceso Interno'), findsOneWidget);
    expect(find.text('Servicios'), findsNothing);
    expect(repository.guardada, isNull);
    expect(SessionStore.isAuthenticated, isFalse);
  });

  testWidgets('un token de tecnico guardado a mano termina en el login',
      (WidgetTester tester) async {
    final repository = _FakeAuthRepository(
      guardada: AuthSession(
        token: jwtDePrueba(roles: <String>['tecnico']),
        email: 'tecnico@empresa.com',
        // Roles editados a mano en el storage: el token firmado manda.
        roles: const <String>['admin-tecnico'],
      ),
    );

    await tester.pumpWidget(WebAdminTecnicoApp(authRepository: repository));
    await tester.pump();
    await tester.pump();

    expect(find.text('Acceso Interno'), findsOneWidget);
    expect(find.text('Este panel es solo para administración'), findsOneWidget);
    expect(repository.guardada, isNull);
    expect(SessionStore.isAuthenticated, isFalse);
  });
}

AuthSession _sesionAdmin() => AuthSession(
      token: jwtDePrueba(
        roles: <String>['admin-tecnico'],
        exp: DateTime.now().add(const Duration(hours: 2)),
      ),
      email: 'admin@empresa.com',
      id: 'u-1',
      fullName: 'Ana Admin',
      roles: const <String>['admin-tecnico'],
    );

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AuthSession? guardada}) : _guardada = guardada;

  AuthSession? _guardada;

  AuthSession? get guardada => _guardada;

  @override
  Future<AuthSession> login(LoginInput input) async =>
      throw UnimplementedError('El login no se ejercita en este test');

  @override
  Future<AuthSession?> sesionGuardada() async => _guardada;

  @override
  Future<void> guardarSesion(AuthSession session) async => _guardada = session;

  @override
  Future<void> logout() async => _guardada = null;
}
