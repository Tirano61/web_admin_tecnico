import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/features/tecnicos/data/tecnicos_repository_impl.dart';
import 'package:web_admin_tecnico/features/tecnicos/domain/tecnicos_repository.dart';

void main() {
  group('TecnicosRepositoryImpl listado', () {
    test('manda activos explicito al pedir los inactivos', () async {
      // Si se omite `activos` el backend devuelve solo los activos.
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.fetchTecnicos(
        query: const TecnicosQuery(activos: FiltroEstadoTecnicos.inactivos, page: 2, limit: 10),
      );

      final call = client.calls.single;
      expect(call.endpoint, '/auth/tecnicos');
      expect(call.queryParameters['activos'], 'false');
      expect(call.queryParameters['page'], '2');
      expect(call.queryParameters['limit'], '10');
      expect(call.queryParameters.containsKey('q'), isFalse);
    });

    test('el filtro TODOS manda activos=todos', () async {
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.fetchTecnicos(
        query: const TecnicosQuery(activos: FiltroEstadoTecnicos.todos),
      );

      expect(client.calls.single.queryParameters['activos'], 'todos');
    });

    test('por defecto manda activos=true', () async {
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.fetchTecnicos(query: const TecnicosQuery());

      expect(client.calls.single.queryParameters['activos'], 'true');
    });

    test('manda q solo cuando hay busqueda', () async {
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.fetchTecnicos(query: const TecnicosQuery(search: '  juan  '));

      expect(client.calls.single.queryParameters['q'], 'juan');
    });

    test('mapea data y meta del listado, roles incluidos', () async {
      final client = _RecordingHttpClient(
        response: <String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{
              'id': 'tec-1',
              'fullName': 'Juan Perez',
              'email': 'juan@example.com',
              'isActive': true,
              'roles': <dynamic>['tecnico'],
            },
          ],
          'meta': <String, dynamic>{
            'page': 1,
            'limit': 20,
            'total': 1,
            'totalPages': 1,
          },
        },
      );
      final repository = TecnicosRepositoryImpl(httpClient: client);

      final result = await repository.fetchTecnicos(query: const TecnicosQuery());

      expect(result.total, 1);
      expect(result.page, 1);
      expect(result.limit, 20);

      final item = result.items.single;
      expect(item.id, 'tec-1');
      expect(item.fullName, 'Juan Perez');
      expect(item.email, 'juan@example.com');
      expect(item.isActive, isTrue);
      expect(item.roles, <String>['tecnico']);
    });
  });

  group('TecnicosRepositoryImpl detalle', () {
    test('lee las fechas de alta y modificacion en snake_case', () async {
      final client = _RecordingHttpClient(
        response: <String, dynamic>{
          'id': 'tec-1',
          'fullName': 'Juan Perez',
          'email': 'juan@example.com',
          'isActive': false,
          'roles': <dynamic>['tecnico'],
          'created_at': '2026-07-11T10:00:00.000Z',
          'updated_at': '2026-07-12T10:00:00.000Z',
        },
      );
      final repository = TecnicosRepositoryImpl(httpClient: client);

      final detalle = await repository.fetchTecnicoDetalle('tec-1');

      expect(client.calls.single.endpoint, '/auth/tecnicos/tec-1');
      expect(detalle.isActive, isFalse);
      expect(detalle.createdAt, '2026-07-11T10:00:00.000Z');
      expect(detalle.updatedAt, '2026-07-12T10:00:00.000Z');
    });
  });

  group('TecnicosRepositoryImpl escritura', () {
    test('el alta manda el shape de CreateTecnicoDto y no el rol', () async {
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.createTecnico(
        input: const CreateTecnicoInput(
          email: ' nuevo@example.com ',
          password: 'ClaveSegura123!',
          fullName: ' Tecnico Nuevo ',
          isActive: false,
        ),
      );

      final call = client.calls.single;
      expect(call.method, 'POST');
      expect(call.endpoint, '/auth/tecnicos');
      expect(call.body, <String, dynamic>{
        'email': 'nuevo@example.com',
        'password': 'ClaveSegura123!',
        'fullName': 'Tecnico Nuevo',
        'isActive': false,
      });
    });

    test('la edicion manda fullName y email juntos', () async {
      // `updateTecnico` del backend rechaza el PATCH si no llega al menos uno
      // de los dos campos.
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.updateTecnico(
        input: const UpdateTecnicoInput(
          id: 'tec-1',
          fullName: 'Juan Perez Actualizado',
          email: 'juan.perez@example.com',
        ),
      );

      final call = client.calls.single;
      expect(call.method, 'PATCH');
      expect(call.endpoint, '/auth/tecnicos/tec-1');
      expect(call.body, <String, dynamic>{
        'fullName': 'Juan Perez Actualizado',
        'email': 'juan.perez@example.com',
      });
    });

    test('el cambio de estado pega en /estado con isActive', () async {
      final client = _RecordingHttpClient();
      final repository = TecnicosRepositoryImpl(httpClient: client);

      await repository.updateEstadoTecnico(tecnicoId: 'tec-1', isActive: false);

      final call = client.calls.single;
      expect(call.method, 'PATCH');
      expect(call.endpoint, '/auth/tecnicos/tec-1/estado');
      expect(call.body, <String, dynamic>{'isActive': false});
    });
  });
}

class _RecordingHttpCall {
  const _RecordingHttpCall({
    required this.method,
    required this.endpoint,
    this.queryParameters = const <String, String>{},
    this.body = const <String, dynamic>{},
  });

  final String method;
  final String endpoint;
  final Map<String, String> queryParameters;
  final Map<String, dynamic> body;
}

class _RecordingHttpClient extends AuthenticatedHttpClient {
  _RecordingHttpClient({this.response}) : super(baseUrl: 'https://example.test/api/v1');

  final dynamic response;
  final List<_RecordingHttpCall> calls = <_RecordingHttpCall>[];

  @override
  Future<dynamic> getJson(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    bool keepEmptyQueryParameters = false,
  }) async {
    calls.add(
      _RecordingHttpCall(
        method: 'GET',
        endpoint: endpoint,
        queryParameters: Map<String, String>.from(queryParameters ?? const <String, String>{}),
      ),
    );

    return response ??
        <String, dynamic>{
          'data': <dynamic>[],
          'meta': <String, dynamic>{'page': 1, 'limit': 20, 'total': 0},
        };
  }

  @override
  Future<dynamic> postJson(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    bool keepEmptyQueryParameters = false,
  }) async {
    calls.add(
      _RecordingHttpCall(
        method: 'POST',
        endpoint: endpoint,
        queryParameters: Map<String, String>.from(queryParameters ?? const <String, String>{}),
        body: Map<String, dynamic>.from(body ?? const <String, dynamic>{}),
      ),
    );

    return response ?? const <String, dynamic>{};
  }

  @override
  Future<dynamic> patchJson(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    bool keepEmptyQueryParameters = false,
  }) async {
    calls.add(
      _RecordingHttpCall(
        method: 'PATCH',
        endpoint: endpoint,
        queryParameters: Map<String, String>.from(queryParameters ?? const <String, String>{}),
        body: Map<String, dynamic>.from(body ?? const <String, dynamic>{}),
      ),
    );

    return response ?? const <String, dynamic>{};
  }
}
