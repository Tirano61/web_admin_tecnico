import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/roles_panel.dart';
import 'package:web_admin_tecnico/features/auth/domain/validador_sesion_persistida.dart';

import '../../../support/jwt_de_prueba.dart';

void main() {
  const validador = ValidadorSesionPersistida();

  AuthSession sesion({required String token, List<String> roles = const <String>[]}) {
    return AuthSession(
      token: token,
      email: 'admin@empresa.com',
      id: 'guardado',
      fullName: 'Ana Admin',
      roles: roles,
    );
  }

  test('sin sesion guardada no hay nada que restaurar', () {
    final resultado = validador.validar(null);

    expect(resultado.esValida, isFalse);
    expect(resultado.motivo, MotivoSesionInvalida.sinSesion);
    expect(resultado.motivo?.mensaje, isNull);
  });

  test('un token vacio se descarta', () {
    final resultado = validador.validar(sesion(token: '   ', roles: <String>['admin']));

    expect(resultado.motivo, MotivoSesionInvalida.sinSesion);
  });

  test('un token ilegible se descarta', () {
    final resultado = validador.validar(sesion(token: 'no-es-un-jwt', roles: <String>['admin']));

    expect(resultado.motivo, MotivoSesionInvalida.tokenIlegible);
  });

  test('un token vencido se descarta', () {
    final token = jwtDePrueba(
      roles: <String>['admin-tecnico'],
      exp: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    final resultado = validador.validar(sesion(token: token, roles: <String>['admin-tecnico']));

    expect(resultado.motivo, MotivoSesionInvalida.tokenVencido);
    expect(resultado.motivo?.mensaje, contains('expiro'));
  });

  test('un token de tecnico no entra al panel', () {
    final token = jwtDePrueba(roles: <String>['tecnico']);

    final resultado = validador.validar(sesion(token: token, roles: <String>['tecnico']));

    expect(resultado.motivo, MotivoSesionInvalida.rolSinAcceso);
    expect(resultado.motivo?.mensaje, RolesPanel.mensajeAccesoDenegado);
  });

  test('los roles del token mandan sobre los roles guardados a mano', () {
    final token = jwtDePrueba(roles: <String>['tecnico']);

    final resultado = validador.validar(sesion(token: token, roles: <String>['admin-tecnico']));

    expect(resultado.motivo, MotivoSesionInvalida.rolSinAcceso);
  });

  test('un admin-tecnico vigente restaura la sesion con id y roles del token', () {
    final token = jwtDePrueba(
      roles: <String>['admin-tecnico'],
      id: 'u-firmado',
      exp: DateTime.now().add(const Duration(hours: 2)),
    );

    final resultado = validador.validar(sesion(token: token, roles: <String>['admin-tecnico']));
    final restaurada = resultado.session;

    expect(resultado.esValida, isTrue);
    expect(restaurada?.id, 'u-firmado');
    expect(restaurada?.roles, <String>['admin-tecnico']);
    expect(restaurada?.token, token);
    // Los datos de presentacion salen del usuario persistido.
    expect(restaurada?.email, 'admin@empresa.com');
    expect(restaurada?.fullName, 'Ana Admin');
  });

  test('un admin superusuario tambien entra', () {
    final token = jwtDePrueba(roles: <String>['admin']);

    final resultado = validador.validar(sesion(token: token, roles: <String>['admin']));

    expect(resultado.esValida, isTrue);
  });

  test('si el token no trae roles se usan los guardados', () {
    const token = 'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6InUtMSJ9.firma';

    final resultado = validador.validar(sesion(token: token, roles: <String>['admin-tecnico']));

    expect(resultado.esValida, isTrue);
    expect(resultado.session?.roles, <String>['admin-tecnico']);
  });
}
