import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/features/servicios/data/servicios_repository_impl.dart';

void main() {
  group('ServiciosRepositoryImpl combo de tecnicos', () {
    test('pide activos=todos: el filtro es sobre servicios historicos', () async {
      final client = _RecordingHttpClient();
      final repository = ServiciosRepositoryImpl(httpClient: client);

      await repository.fetchTecnicosFiltro();

      final call = client.calls.single;
      expect(call.endpoint, '/auth/tecnicos');
      expect(call.queryParameters['activos'], 'todos');
    });

    test('incluye los inactivos, ordenados despues de los activos', () async {
      final client = _RecordingHttpClient(
        response: <String, dynamic>{
          'data': <dynamic>[
            <String, dynamic>{'id': 't-1', 'fullName': 'Ana', 'email': 'ana@x.com', 'isActive': false},
            <String, dynamic>{'id': 't-2', 'fullName': 'Zoe', 'email': 'zoe@x.com', 'isActive': true},
            <String, dynamic>{'id': 't-3', 'fullName': 'Beto', 'email': 'beto@x.com', 'isActive': true},
          ],
          'meta': <String, dynamic>{'page': 1, 'limit': 100, 'total': 3, 'totalPages': 1},
        },
      );
      final repository = ServiciosRepositoryImpl(httpClient: client);

      final tecnicos = await repository.fetchTecnicosFiltro();

      expect(tecnicos.map((t) => t.id).toList(), <String>['t-3', 't-2', 't-1']);
      expect(tecnicos.last.isActive, isFalse);
    });
  });
}

class _RecordingHttpCall {
  const _RecordingHttpCall({
    required this.endpoint,
    this.queryParameters = const <String, String>{},
  });

  final String endpoint;
  final Map<String, String> queryParameters;
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
        endpoint: endpoint,
        queryParameters: queryParameters ?? const <String, String>{},
      ),
    );
    return response ??
        <String, dynamic>{
          'data': <dynamic>[],
          'meta': <String, dynamic>{'page': 1, 'limit': 100, 'total': 0, 'totalPages': 0},
        };
  }
}
