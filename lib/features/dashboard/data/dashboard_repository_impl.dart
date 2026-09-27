import 'dart:developer' as developer;

import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/dashboard/domain/dashboard_repository.dart';

/// Arma las metricas con los listados paginados existentes, leyendo solo
/// `meta.total` (con `limit=1` para no traer filas de mas):
/// - `GET /servicios?desde=&canal=`          servicios del mes y por canal
/// - `GET /liquidaciones?estado=pendiente`   pendientes (+ antiguedad por createdAt)
/// - `GET /liquidaciones?estado=reabierta`   reabiertas
/// - `GET /liquidaciones/para-pago`          aprobadas listas para pago
/// - `GET /auth/tecnicos?activos=true`       tecnicos activos
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  static const List<String> _canales = <String>['campo', 'remoto', 'fabrica'];

  /// `/liquidaciones` ordena por createdAt DESC: las pendientes mas viejas
  /// quedan al final, asi que hay que recorrer todas las paginas para contarlas.
  static const int _limitePendientes = 100;
  static const int _maxPaginasPendientes = 20;

  @override
  Future<DashboardMetricas> fetchMetricas({required DashboardQuery query}) async {
    final resultados = await Future.wait<Object?>(<Future<Object?>>[
      _intentar('servicios del mes', () => _fetchServiciosMes(query.inicioMes)),
      _intentar(
        'liquidaciones pendientes',
        () => _fetchPendientes(query.limiteAntiguedadPendientes),
      ),
      _intentar(
        'liquidaciones reabiertas',
        () => _contar('/liquidaciones', <String, String>{'estado': 'reabierta'}),
      ),
      _intentar(
        'liquidaciones para pago',
        () => _contar('/liquidaciones/para-pago', const <String, String>{}),
      ),
      _intentar(
        'tecnicos activos',
        () => _contar('/auth/tecnicos', <String, String>{'activos': 'true'}),
      ),
    ]);

    return DashboardMetricas(
      diasAlertaPendientes: query.diasAlertaPendientes,
      serviciosMes: resultados[0] as ServiciosMesMetrica?,
      liquidacionesPendientes: resultados[1] as LiquidacionesPendientesMetrica?,
      liquidacionesReabiertas: resultados[2] as int?,
      liquidacionesParaPago: resultados[3] as int?,
      tecnicosActivos: resultados[4] as int?,
    );
  }

  Future<ServiciosMesMetrica> _fetchServiciosMes(DateTime inicioMes) async {
    // `desde` filtra por `caso.fecha` (FilterServiciosDto). Se manda el instante
    // en UTC para que el corte respete la medianoche local del dia 1.
    final desde = inicioMes.toUtc().toIso8601String();
    final totales = await Future.wait<int>(<Future<int>>[
      _contar('/servicios', <String, String>{'desde': desde}),
      for (final canal in _canales)
        _contar('/servicios', <String, String>{'desde': desde, 'canal': canal}),
    ]);

    return ServiciosMesMetrica(
      total: totales[0],
      campo: totales[1],
      remoto: totales[2],
      fabrica: totales[3],
    );
  }

  Future<LiquidacionesPendientesMetrica> _fetchPendientes(DateTime limiteAntiguedad) async {
    var total = 0;
    var antiguas = 0;
    var page = 1;
    var totalPaginas = 1;

    do {
      final payload = await _httpClient.getJson(
        '/liquidaciones',
        queryParameters: <String, String>{
          'estado': 'pendiente',
          'page': page.toString(),
          'limit': _limitePendientes.toString(),
        },
      );
      final result = PagedResult<DateTime?>.fromDynamic(
        payload,
        (json) => _parseFecha(json['createdAt'] ?? json['created_at']),
        fallbackPage: page,
        fallbackLimit: _limitePendientes,
      );

      total = result.total;
      antiguas += result.items
          .whereType<DateTime>()
          .where((creada) => creada.isBefore(limiteAntiguedad))
          .length;
      totalPaginas = result.limit > 0 ? (result.total / result.limit).ceil() : 1;
      page++;
    } while (page <= totalPaginas && page <= _maxPaginasPendientes);

    return LiquidacionesPendientesMetrica(total: total, antiguas: antiguas);
  }

  Future<int> _contar(String endpoint, Map<String, String> filtros) async {
    final payload = await _httpClient.getJson(
      endpoint,
      queryParameters: <String, String>{...filtros, 'page': '1', 'limit': '1'},
    );
    return PagedResult<Object?>.fromDynamic(payload, (json) => json).total;
  }

  Future<Object?> _intentar(String metrica, Future<Object?> Function() cargar) async {
    try {
      return await cargar();
    } catch (error) {
      developer.log('No se pudo cargar $metrica: $error', name: 'DashboardRepository');
      return null;
    }
  }

  static DateTime? _parseFecha(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim());
  }
}
