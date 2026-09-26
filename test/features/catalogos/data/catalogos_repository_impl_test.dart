import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/features/catalogos/data/catalogos_repository_impl.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';

void main() {
  group('CatalogosRepositoryImpl listado', () {
    // Sin `activo`, /zonas, /categorias-producto y /productos devuelven solo los
    // activos: el panel manda `todos` para poder ver y reactivar los inactivos.
    for (final (tipo, endpoint) in <(String, String)>[
      ('zona', '/zonas'),
      ('categoria', '/categorias-producto'),
      ('producto', '/productos'),
    ]) {
      test('$tipo manda activo=todos y no pagina en el backend', () async {
        final client = _RecordingHttpClient();
        final repository = CatalogosRepositoryImpl(httpClient: client);

        await repository.fetchCatalogos(query: CatalogosQuery(tipo: tipo, search: 'x'));

        final call = client.calls.single;
        expect(call.endpoint, endpoint);
        expect(call.queryParameters, <String, String>{'activo': 'todos'});
      });
    }

    test('un filtro explicito de activo se respeta', () async {
      final client = _RecordingHttpClient();
      final repository = CatalogosRepositoryImpl(httpClient: client);

      await repository.fetchCatalogos(query: const CatalogosQuery(tipo: 'zona', activo: false));

      expect(client.calls.single.queryParameters['activo'], 'false');
    });

    test('repuestos no manda activo si no hay filtro', () async {
      // En /repuestos/listado omitir `activo` ya trae activos e inactivos.
      final client = _RecordingHttpClient();
      final repository = CatalogosRepositoryImpl(httpClient: client);

      await repository.fetchCatalogos(query: const CatalogosQuery(tipo: 'repuesto'));

      final params = client.calls.single.queryParameters;
      expect(params.containsKey('activo'), isFalse);
      expect(params['page'], '1');
    });
  });

  group('CatalogosRepositoryImpl productos por categoria', () {
    test('trae categorias y productos inactivos', () async {
      final client = _RecordingHttpClient(
        responses: <String, dynamic>{
          '/categorias-producto': <dynamic>[
            <String, dynamic>{'id': 'cat-1', 'nombre': 'Celdas', 'activo': false},
          ],
          '/productos': <dynamic>[
            <String, dynamic>{'id': 'p-1', 'nombre': 'Celda 1', 'activo': false},
          ],
        },
      );
      final repository = CatalogosRepositoryImpl(httpClient: client);

      final grupos = await repository.fetchProductosPorCategoria(search: '');

      expect(client.calls.first.queryParameters, <String, String>{'activo': 'todos'});
      expect(
        client.calls.last.queryParameters,
        <String, String>{'categoriaId': 'cat-1', 'activo': 'todos'},
      );
      expect(grupos.single.categoriaActiva, isFalse);
      expect(grupos.single.productos.single.activo, isFalse);
      expect(grupos.single.productos.single.categoriaId, 'cat-1');
    });

    test('el selector del alta pide solo categorias activas', () async {
      final client = _RecordingHttpClient();
      final repository = CatalogosRepositoryImpl(httpClient: client);

      await repository.fetchCategorias();

      expect(client.calls.single.queryParameters, isEmpty);
    });
  });
}

class _RecordingHttpCall {
  const _RecordingHttpCall({required this.endpoint, required this.queryParameters});

  final String endpoint;
  final Map<String, String> queryParameters;
}

class _RecordingHttpClient extends AuthenticatedHttpClient {
  _RecordingHttpClient({this.responses = const <String, dynamic>{}})
      : super(baseUrl: 'https://example.test/api/v1');

  final Map<String, dynamic> responses;
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
    return responses[endpoint] ?? <dynamic>[];
  }
}
