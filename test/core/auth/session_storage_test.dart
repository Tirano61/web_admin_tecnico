import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/session_storage.dart';

import '../../support/jwt_de_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> almacenado;
  late SecureSessionStorage storage;

  setUp(() {
    almacenado = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(almacenado);
    storage = SecureSessionStorage();
  });

  test('guarda token y usuario en claves separadas', () async {
    final token = jwtDePrueba(roles: <String>['admin-tecnico']);

    await storage.guardar(
      AuthSession(
        token: token,
        email: 'admin@empresa.com',
        id: 'u-1',
        fullName: 'Ana Admin',
        roles: const <String>['admin-tecnico'],
      ),
    );

    expect(almacenado[SecureSessionStorage.tokenKey], token);
    final usuario = jsonDecode(almacenado[SecureSessionStorage.usuarioKey]!) as Map<String, dynamic>;
    expect(usuario['id'], 'u-1');
    expect(usuario['fullName'], 'Ana Admin');
    expect(usuario['email'], 'admin@empresa.com');
    expect(usuario['roles'], <String>['admin-tecnico']);
    // El token no se duplica adentro del usuario.
    expect(usuario.containsKey('token'), isFalse);
  });

  test('vuelve a leer la sesion completa (sobrevive al F5)', () async {
    final token = jwtDePrueba(roles: <String>['admin-tecnico']);
    final original = AuthSession(
      token: token,
      email: 'admin@empresa.com',
      id: 'u-1',
      fullName: 'Ana Admin',
      roles: const <String>['admin-tecnico'],
    );

    await storage.guardar(original);
    final leida = await storage.leer();

    expect(leida?.token, token);
    expect(leida?.email, 'admin@empresa.com');
    expect(leida?.id, 'u-1');
    expect(leida?.fullName, 'Ana Admin');
    expect(leida?.roles, <String>['admin-tecnico']);
  });

  test('sin token guardado no hay sesion', () async {
    expect(await storage.leer(), isNull);
  });

  test('un usuario corrupto no rompe la lectura del token', () async {
    almacenado[SecureSessionStorage.tokenKey] = 'jwt';
    almacenado[SecureSessionStorage.usuarioKey] = 'no-es-json';

    final leida = await storage.leer();

    expect(leida?.token, 'jwt');
    expect(leida?.roles, isEmpty);
  });

  test('limpiar borra token y usuario', () async {
    await storage.guardar(
      AuthSession(
        token: jwtDePrueba(roles: <String>['admin']),
        email: 'admin@empresa.com',
        roles: const <String>['admin'],
      ),
    );

    await storage.limpiar();

    expect(almacenado, isEmpty);
    expect(await storage.leer(), isNull);
  });
}
