import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/auth/data/auth_repository_impl.dart';
import 'package:web_admin_tecnico/features/auth/domain/auth_repository.dart';

void main() {
  group('AuthRepositoryImpl login', () {
    test('lee access_token y el usuario con sus roles', () async {
      final client = _FakeHttpClient(
        response: <String, dynamic>{
          'access_token': 'jwt-admin-tecnico',
          'user': <String, dynamic>{
            'id': '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c',
            'fullName': 'Juan Perez',
            'email': 'admin@empresa.com',
            'roles': <String>['admin-tecnico'],
          },
        },
      );
      final repository = AuthRepositoryImpl(httpClient: client);

      final session = await repository.login(
        const LoginInput(email: 'admin@empresa.com', password: 'Abc123'),
      );

      expect(session.token, 'jwt-admin-tecnico');
      expect(session.id, '8f3b1c2a-4d5e-4a7b-9c10-2f6e8d1a3b4c');
      expect(session.fullName, 'Juan Perez');
      expect(session.email, 'admin@empresa.com');
      expect(session.roles, <String>['admin-tecnico']);
      expect(session.puedeAccederAlPanel, isTrue);
      expect(client.calls.single, '/auth/login');
    });

    test('conserva todos los roles del usuario', () async {
      final client = _FakeHttpClient(
        response: <String, dynamic>{
          'access_token': 'jwt-multi',
          'user': <String, dynamic>{
            'id': 'u-2',
            'fullName': 'Ana Gomez',
            'email': 'ana@empresa.com',
            'roles': <String>['tecnico', 'admin-tecnico'],
          },
        },
      );
      final repository = AuthRepositoryImpl(httpClient: client);

      final session = await repository.login(
        const LoginInput(email: 'ana@empresa.com', password: 'Abc123'),
      );

      expect(session.roles, <String>['tecnico', 'admin-tecnico']);
      expect(session.puedeAccederAlPanel, isTrue);
    });

    test('parsea el rol tecnico sin acceso al panel', () async {
      final client = _FakeHttpClient(
        response: <String, dynamic>{
          'access_token': 'jwt-tecnico',
          'user': <String, dynamic>{
            'id': 'u-3',
            'fullName': 'Pedro Lopez',
            'email': 'tecnico@empresa.com',
            'roles': <String>['tecnico'],
          },
        },
      );
      final repository = AuthRepositoryImpl(httpClient: client);

      final session = await repository.login(
        const LoginInput(email: 'tecnico@empresa.com', password: 'Abc123'),
      );

      expect(session.token, 'jwt-tecnico');
      expect(session.roles, <String>['tecnico']);
      expect(session.puedeAccederAlPanel, isFalse);
    });

    test('falla si la respuesta no trae access_token', () async {
      final client = _FakeHttpClient(
        response: <String, dynamic>{
          'user': <String, dynamic>{'id': 'u-4', 'roles': <String>['admin']},
        },
      );
      final repository = AuthRepositoryImpl(httpClient: client);

      expect(
        () => repository.login(
          const LoginInput(email: 'admin@empresa.com', password: 'Abc123'),
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('soporta la respuesta envuelta en data', () async {
      final client = _FakeHttpClient(
        response: <String, dynamic>{
          'data': <String, dynamic>{
            'access_token': 'jwt-envuelto',
            'user': <String, dynamic>{
              'id': 'u-5',
              'fullName': 'Sofia Diaz',
              'email': 'sofia@empresa.com',
              'roles': <String>['admin'],
            },
          },
        },
      );
      final repository = AuthRepositoryImpl(httpClient: client);

      final session = await repository.login(
        const LoginInput(email: 'sofia@empresa.com', password: 'Abc123'),
      );

      expect(session.token, 'jwt-envuelto');
      expect(session.roles, <String>['admin']);
      expect(session.puedeAccederAlPanel, isTrue);
    });

    test('sin roles en la respuesta no habilita el panel', () async {
      final client = _FakeHttpClient(
        response: <String, dynamic>{
          'access_token': 'jwt-sin-roles',
          'user': <String, dynamic>{'id': 'u-6', 'email': 'x@empresa.com'},
        },
      );
      final repository = AuthRepositoryImpl(httpClient: client);

      final session = await repository.login(
        const LoginInput(email: 'x@empresa.com', password: 'Abc123'),
      );

      expect(session.roles, isEmpty);
      expect(session.puedeAccederAlPanel, isFalse);
    });
  });
}

class _FakeHttpClient extends AuthenticatedHttpClient {
  _FakeHttpClient({required this.response}) : super(baseUrl: 'http://test/api/v1');

  final dynamic response;
  final List<String> calls = <String>[];

  @override
  Future<dynamic> postJson(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    bool keepEmptyQueryParameters = false,
  }) async {
    calls.add(endpoint);
    return response;
  }
}
