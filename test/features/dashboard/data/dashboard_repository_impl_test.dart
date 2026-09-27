import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:web_admin_tecnico/features/dashboard/domain/dashboard_repository.dart';

void main() {
  final ahora = DateTime(2026, 9, 27, 10);
  final query = DashboardQuery.paraFecha(ahora);

  group('DashboardQuery', () {
    test('el periodo arranca el dia 1 del mes y la alerta es a 7 dias', () {
      expect(query.inicioMes, DateTime(2026, 9));
      expect(query.limiteAntiguedadPendientes, DateTime(2026, 9, 20, 10));
      expect(query.diasAlertaPendientes, 7);
    });
  });

  group('DashboardRepositoryImpl', () {
    test('cuenta con meta.total de los listados existentes', () async {
      final client = _FakeHttpClient((endpoint, params) {
        if (endpoint == '/servicios') {
          return _page(total: switch (params['canal']) {
            'campo' => 5,
            'remoto' => 3,
            'fabrica' => 1,
            _ => 9,
          });
        }
        if (endpoint == '/liquidaciones' && params['estado'] == 'reabierta') {
          return _page(total: 2);
        }
        if (endpoint == '/liquidaciones/para-pago') {
          return _page(total: 4);
        }
        if (endpoint == '/auth/tecnicos') {
          return _page(total: 6);
        }
        return _page(total: 0);
      });

      final metricas = await DashboardRepositoryImpl(httpClient: client).fetchMetricas(query: query);

      expect(metricas.serviciosMes?.total, 9);
      expect(metricas.serviciosMes?.campo, 5);
      expect(metricas.serviciosMes?.remoto, 3);
      expect(metricas.serviciosMes?.fabrica, 1);
      expect(metricas.liquidacionesReabiertas, 2);
      expect(metricas.liquidacionesParaPago, 4);
      expect(metricas.tecnicosActivos, 6);

      final servicios = client.calls.where((c) => c.endpoint == '/servicios');
      expect(servicios, hasLength(4));
      expect(
        servicios.every((c) => c.params['desde'] == DateTime(2026, 9).toUtc().toIso8601String()),
        isTrue,
      );
      final tecnicos = client.calls.singleWhere((c) => c.endpoint == '/auth/tecnicos');
      expect(tecnicos.params['activos'], 'true');
      expect(tecnicos.params['limit'], '1');
    });

    test('recorre todas las paginas de pendientes y cuenta las antiguas', () async {
      final client = _FakeHttpClient((endpoint, params) {
        if (endpoint == '/liquidaciones' && params['estado'] == 'pendiente') {
          // 150 pendientes: la pagina 2 (las mas viejas) trae 3 de hace 10 dias.
          if (params['page'] == '1') {
            return _page(
              total: 150,
              limit: 100,
              items: List<Map<String, dynamic>>.generate(
                100,
                (_) => <String, dynamic>{'createdAt': '2026-09-26T12:00:00.000Z'},
              ),
            );
          }
          return _page(
            total: 150,
            limit: 100,
            items: <Map<String, dynamic>>[
              for (var i = 0; i < 47; i++) <String, dynamic>{'createdAt': '2026-09-25T12:00:00.000Z'},
              for (var i = 0; i < 3; i++) <String, dynamic>{'createdAt': '2026-09-17T12:00:00.000Z'},
            ],
          );
        }
        return _page(total: 0);
      });

      final metricas = await DashboardRepositoryImpl(httpClient: client).fetchMetricas(query: query);

      expect(metricas.liquidacionesPendientes?.total, 150);
      expect(metricas.liquidacionesPendientes?.antiguas, 3);
      expect(metricas.requiereAtencion, isTrue);
      expect(
        client.calls.where((c) => c.params['estado'] == 'pendiente').map((c) => c.params['page']),
        <String>['1', '2'],
      );
    });

    test('si un endpoint falla, esa metrica queda en null y el resto se muestra', () async {
      final client = _FakeHttpClient((endpoint, params) {
        if (endpoint == '/servicios') {
          throw const AppFailure('desde invalido', statusCode: 400);
        }
        return _page(total: 1);
      });

      final metricas = await DashboardRepositoryImpl(httpClient: client).fetchMetricas(query: query);

      expect(metricas.serviciosMes, isNull);
      expect(metricas.tecnicosActivos, 1);
      expect(metricas.sinDatos, isFalse);
    });
  });
}

Map<String, dynamic> _page({
  required int total,
  int limit = 1,
  List<Map<String, dynamic>> items = const <Map<String, dynamic>>[],
}) {
  return <String, dynamic>{
    'data': items,
    'meta': <String, dynamic>{
      'page': 1,
      'limit': limit,
      'total': total,
      'totalPages': (total / limit).ceil(),
    },
  };
}

class _Call {
  const _Call(this.endpoint, this.params);

  final String endpoint;
  final Map<String, String> params;
}

class _FakeHttpClient extends AuthenticatedHttpClient {
  _FakeHttpClient(this._responder) : super(baseUrl: 'https://example.test/api/v1');

  final dynamic Function(String endpoint, Map<String, String> params) _responder;
  final List<_Call> calls = <_Call>[];

  @override
  Future<dynamic> getJson(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    bool keepEmptyQueryParameters = false,
  }) async {
    final params = queryParameters ?? const <String, String>{};
    calls.add(_Call(endpoint, params));
    return _responder(endpoint, params);
  }
}
