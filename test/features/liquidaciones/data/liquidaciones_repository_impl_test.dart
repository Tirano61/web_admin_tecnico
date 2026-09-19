import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/data/liquidaciones_repository_impl.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

void main() {
  _mainHidratacionCliente();
  _mainReabiertas();

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

void _mainReabiertas() {
  group('LiquidacionesRepositoryImpl reabiertas', () {
    test('filtra por estado=reabierta en vez de aprobado', () async {
      // Reabrir deja aprobado=false: filtrar por aprobado ya no distingue una
      // reabierta de una pendiente.
      final client = _RecordingHttpClient();
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      await repository.fetchLiquidaciones(
        query: LiquidacionesQuery(
          tecnicoId: 'tec-1',
          estado: LiquidacionEstadoFiltro.reabierta.queryValue,
          liquidadaPago: false,
          page: 1,
          limit: 50,
        ),
      );

      final call = client.calls.first;
      expect(call.endpoint, '/liquidaciones');
      expect(call.queryParameters['estado'], 'reabierta');
      expect(call.queryParameters['liquidadaPago'], 'false');
      expect(call.queryParameters.containsKey('aprobado'), isFalse);
    });

    test('el filtro todas no manda el parametro estado', () async {
      final client = _RecordingHttpClient();
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      await repository.fetchLiquidaciones(
        query: LiquidacionesQuery(
          estado: LiquidacionEstadoFiltro.todas.queryValue,
          page: 1,
          limit: 20,
        ),
      );

      expect(client.calls.first.queryParameters.containsKey('estado'), isFalse);
    });

    test('mapea motivo y fecha de reapertura, y la deja fuera de pago', () async {
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones': _liquidacionReabiertaPayload(),
        },
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchLiquidaciones(
        query: const LiquidacionesQuery(estado: 'reabierta'),
      );

      final item = result.items.single;
      expect(item.estadoNormalizado, 'reabierta');
      expect(item.isReabierta, isTrue);
      expect(item.motivoReapertura, 'Faltaba cargar un item');
      expect(item.fechaReapertura, '2026-07-12T09:00:00.000Z');
      expect(item.fechaAprobacion, isNull);
      expect(item.isElegibleParaPago, isFalse);
    });

    test('hidratar el cliente no pierde el motivo de reapertura', () async {
      // El item se reconstruia campo por campo al hidratar: cualquier dato
      // nuevo se perdia justo en las filas sin cliente.
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones': _liquidacionReabiertaPayload(conCliente: false),
          '/servicios/srv-9': _servicioPayload('Agro SRL'),
        },
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchLiquidaciones(
        query: const LiquidacionesQuery(estado: 'reabierta'),
      );

      final item = result.items.single;
      expect(item.clienteNombre, 'Agro SRL');
      expect(item.motivoReapertura, 'Faltaba cargar un item');
      expect(item.isReabierta, isTrue);
    });
  });
}

Map<String, dynamic> _liquidacionReabiertaPayload({bool conCliente = true}) {
  return <String, dynamic>{
    'data': <dynamic>[
      <String, dynamic>{
        'id': 'liq-9',
        'servicioId': 'srv-9',
        'servicio': <String, dynamic>{'id': 'srv-9', 'canal': 'campo'},
        'clienteNombre': conCliente ? 'Agro SRL' : null,
        'tipoSalidaNombre': 'Media distancia',
        'tipoSalidaPrecioUsd': 80,
        'km': 40,
        'aprobado': false,
        'estado': 'reabierta',
        'fechaAprobacion': null,
        'motivoReapertura': 'Faltaba cargar un item',
        'fechaReapertura': '2026-07-12T09:00:00.000Z',
        'liquidadaPago': false,
      },
    ],
    'meta': <String, dynamic>{'total': 1, 'page': 1, 'limit': 20},
  };
}

void _mainHidratacionCliente() {
  group('LiquidacionesRepositoryImpl hidratacion de cliente', () {
    test('completa el cliente pidiendo el servicio', () async {
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones/resumen-pago/preview': _previewPayload(),
          '/servicios/srv-1': _servicioPayload('Agro SRL'),
        },
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchResumenPagoPreview(
        query: const ResumenPagoPreviewQuery(
          tecnicoId: 'tec-1',
          desde: '2026-07-01',
          hasta: '2026-07-31',
        ),
      );

      expect(result.items.single.clienteNombre, 'Agro SRL');
      expect(client.callsTo('/servicios/srv-1'), 1);
    });

    test('resuelve el tipo de salida desde GET /liquidaciones', () async {
      // El endpoint de resumen no lo manda y el de items no lo garantiza; el
      // listado de liquidaciones si lo trae.
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones/resumen-pago/preview': _previewPayload(),
          '/liquidaciones': <String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'id': 'liq-1',
                'servicioId': 'srv-1',
                'clienteNombre': 'Agro SRL',
                'tipoSalidaNombre': 'Media distancia',
                'tipoSalidaPrecioUsd': 80,
                'aprobada': true,
                'liquidadaPago': false,
              },
            ],
            'meta': <String, dynamic>{'total': 1, 'page': 1, 'limit': 100},
          },
        },
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchResumenPagoPreview(
        query: const ResumenPagoPreviewQuery(
          tecnicoId: 'tec-1',
          desde: '2026-07-01',
          hasta: '2026-07-31',
        ),
      );

      expect(result.items.single.tipoSalidaNombre, 'Media distancia');
      expect(result.items.single.clienteNombre, 'Agro SRL');
      // El listado ya trajo el cliente: no hace falta ir al servicio.
      expect(client.callsTo('/servicios/srv-1'), 0);
    });

    test('no consulta servicios si el preview ya trae cliente', () async {
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones/resumen-pago/preview': _previewPayload(
            clienteNombre: 'Ya Viene SA',
          ),
        },
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchResumenPagoPreview(
        query: const ResumenPagoPreviewQuery(
          tecnicoId: 'tec-1',
          desde: '2026-07-01',
          hasta: '2026-07-31',
        ),
      );

      expect(result.items.single.clienteNombre, 'Ya Viene SA');
      expect(client.callsTo('/servicios/srv-1'), 0);
    });

    test('si el servicio falla el preview sigue devolviendo la fila', () async {
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones/resumen-pago/preview': _previewPayload(),
        },
        failing: <String>{'/servicios/srv-1'},
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchResumenPagoPreview(
        query: const ResumenPagoPreviewQuery(
          tecnicoId: 'tec-1',
          desde: '2026-07-01',
          hasta: '2026-07-31',
        ),
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.clienteNombre, isNull);
      expect(result.items.single.totalLiquidacionUsd, 200.5);
    });

    test('dos liquidaciones del mismo servicio consultan una sola vez', () async {
      final client = _RouteHttpClient(
        responses: <String, dynamic>{
          '/liquidaciones/resumen-pago/preview': <String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'id': 'liq-1',
                'servicioId': 'srv-1',
                'totalLiquidacionUsd': 200.5,
              },
              <String, dynamic>{
                'id': 'liq-2',
                'servicioId': 'srv-1',
                'totalLiquidacionUsd': 140,
              },
            ],
            'meta': <String, dynamic>{
              'totalLiquidaciones': 2,
              'totalResumenUsd': 340.5,
            },
          },
          '/servicios/srv-1': _servicioPayload('Agro SRL'),
        },
      );
      final repository = LiquidacionesRepositoryImpl(httpClient: client);

      final result = await repository.fetchResumenPagoPreview(
        query: const ResumenPagoPreviewQuery(
          tecnicoId: 'tec-1',
          desde: '2026-07-01',
          hasta: '2026-07-31',
        ),
      );

      expect(result.items.every((item) => item.clienteNombre == 'Agro SRL'), isTrue);
      expect(client.callsTo('/servicios/srv-1'), 1);
    });
  });
}

Map<String, dynamic> _previewPayload({String? clienteNombre}) {
  return <String, dynamic>{
    'data': <dynamic>[
      <String, dynamic>{
        'id': 'liq-1',
        'servicioId': 'srv-1',
        'fechaAprobacion': '2026-07-10T14:20:00.000Z',
        'subtotalSalidaUsd': 80,
        'subtotalItemsUsd': 120.5,
        'totalLiquidacionUsd': 200.5,
        'clienteNombre': ?clienteNombre,
      },
    ],
    'meta': <String, dynamic>{
      'totalLiquidaciones': 1,
      'totalResumenUsd': 200.5,
    },
  };
}

Map<String, dynamic> _servicioPayload(String cliente) {
  return <String, dynamic>{
    'servicio': <String, dynamic>{
      'id': 'srv-1',
      'canal': 'campo',
      'cliente': <String, dynamic>{'nombre': cliente},
      'fechaHoraServicio': '2026-07-09T11:00:00.000Z',
    },
  };
}

class _RouteHttpClient extends AuthenticatedHttpClient {
  _RouteHttpClient({
    required this.responses,
    this.failing = const <String>{},
  }) : super(baseUrl: 'https://example.test/api/v1');

  final Map<String, dynamic> responses;
  final Set<String> failing;
  final List<String> endpoints = <String>[];

  int callsTo(String endpoint) =>
      endpoints.where((value) => value == endpoint).length;

  @override
  Future<dynamic> getJson(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
    bool keepEmptyQueryParameters = false,
  }) async {
    endpoints.add(endpoint);
    if (failing.contains(endpoint)) {
      throw const AppFailure('servicio caido', statusCode: 500);
    }
    return responses[endpoint] ?? const <String, dynamic>{};
  }
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
