import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

void main() {
  group('LiquidacionesRepositoryImpl pendientes', () {
    test('envia estado=pendiente al consultar pendientes', () async {
      final client = _RecordingHttpClient();
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchLiquidacionesPendientes(
        query: const LiquidacionesPendientesQuery(
          tecnicoId: 'tec-1',
          estado: 'pendiente',
          page: 1,
          limit: 20,
        ),
      );

      expect(result, isA<PagedResult<LiquidacionPendienteItem>>());
      expect(client.calls, isNotEmpty);
      expect(client.calls.first.endpoint, '/liquidaciones/pendientes');
      expect(client.calls.first.queryParameters['estado'], 'pendiente');
      expect(client.calls.first.queryParameters['tecnicoId'] ?? client.calls.first.queryParameters['tecnico_id'], 'tec-1');
    });
  });
}

class _RecordingHttpCall {
  const _RecordingHttpCall({
    required this.endpoint,
    required this.queryParameters,
  });

  final String endpoint;
  final Map<String, String> queryParameters;
}

class _RecordingHttpClient extends AuthenticatedHttpClient {
  _RecordingHttpClient() : super(baseUrl: 'https://example.test/api/v1');

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
        queryParameters: Map<String, String>.from(queryParameters ?? const <String, String>{}),
      ),
    );

    return <String, dynamic>{
      'items': <dynamic>[],
      'meta': <String, dynamic>{
        'total': 0,
        'page': 1,
        'limit': 20,
      },
    };
  }
}
