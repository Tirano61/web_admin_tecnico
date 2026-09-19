import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/auth/jwt_token.dart';

import '../../support/jwt_de_prueba.dart';

void main() {
  group('JwtToken', () {
    test('lee id y roles firmados en el token', () {
      final token = jwtDePrueba(roles: <String>['admin-tecnico'], id: 'u-42');

      expect(JwtToken.id(token), 'u-42');
      expect(JwtToken.roles(token), <String>['admin-tecnico']);
      expect(JwtToken.esLegible(token), isTrue);
    });

    test('acepta un rol simple ademas del array', () {
      const token = 'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYWRtaW4ifQ.firma';

      expect(JwtToken.roles(token), <String>['admin']);
    });

    test('un token basura no es legible y no aporta roles', () {
      expect(JwtToken.esLegible('jwt'), isFalse);
      expect(JwtToken.roles('jwt'), isEmpty);
      expect(JwtToken.id('jwt'), isNull);
      expect(JwtToken.expiracion('jwt'), isNull);
    });

    test('un token vencido se detecta como vencido', () {
      final token = jwtDePrueba(
        roles: <String>['admin-tecnico'],
        exp: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(JwtToken.estaVencido(token), isTrue);
    });

    test('un token vigente no se marca vencido', () {
      final token = jwtDePrueba(
        roles: <String>['admin-tecnico'],
        exp: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(JwtToken.estaVencido(token), isFalse);
    });

    test('vence apenas antes del exp, por el margen de seguridad', () {
      final exp = DateTime.now().add(const Duration(seconds: 5));
      final token = jwtDePrueba(roles: <String>['admin'], exp: exp);

      expect(JwtToken.estaVencido(token), isTrue);
    });

    test('sin exp legible decide el backend, no el cliente', () {
      final token = jwtDePrueba(roles: <String>['admin-tecnico']);

      expect(JwtToken.expiracion(token), isNull);
      expect(JwtToken.estaVencido(token), isFalse);
    });
  });
}
