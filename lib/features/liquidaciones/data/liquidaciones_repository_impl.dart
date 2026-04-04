import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesRepositoryImpl implements LiquidacionesRepository {
  LiquidacionesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    dynamic payload;
    try {
      payload = await _httpClient.getJson(
        '/liquidaciones',
        queryParameters: <String, String>{
          'q': query.search,
          'estado': query.estado == 'todos' ? '' : query.estado,
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      );
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }
      payload = await _httpClient.getJson(
        '/liquidaciones',
        queryParameters: <String, String>{
          'q': query.search,
          'estado': query.estado == 'todos' ? '' : query.estado,
        },
      );
    }

    final result = PagedResult<LiquidacionItem>.fromDynamic(
      payload,
      (json) {
        final servicioNode = _asMap(json['servicio']);
        final estado = _stringOrNull(json['estado'] ?? json['estadoLiquidacion'] ?? json['status']);
        return LiquidacionItem(
          id: (json['id'] ?? json['liquidacionId'] ?? '').toString(),
          servicioId: (json['servicioId'] ?? json['servicio_id'] ?? servicioNode['id'] ?? '').toString(),
          montoUsd: _toDouble(
            json['montoUsd'] ??
                json['monto_usd'] ??
                json['totalUsd'] ??
                json['total_usd'] ??
                json['monto'],
          ),
          aprobada: _toBool(json['aprobada'] ?? estado),
          estado: estado,
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    if (result.items.length <= query.limit) {
      return result;
    }

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pagedItems = start >= result.items.length
        ? <LiquidacionItem>[]
        : result.items.sublist(start, end > result.items.length ? result.items.length : end);

    return PagedResult<LiquidacionItem>(
      items: pagedItems,
      total: result.total,
      page: query.page,
      limit: query.limit,
    );
  }

  @override
  Future<LiquidacionItemsResponse> fetchLiquidacionItems(String liquidacionId) async {
    final payload = await _httpClient.getJson('/liquidaciones/${liquidacionId.trim()}/items');
    final root = _asMap(payload);

    final liquidacionIdResponse =
        _stringOrNull(root['liquidacionId'] ?? root['liquidacion_id']) ?? liquidacionId;

    final itemsRaw = root['items'];
    final itemsList = itemsRaw is List ? itemsRaw : const <dynamic>[];
    final items = itemsList
        .map(_asMap)
        .where((json) => _stringOrNull(json['id']) != null)
        .map(
          (json) => LiquidacionItemDetalle(
            id: _stringOrNull(json['id'])!,
            tipoServicioId: _stringOrNull(json['tipoServicioId'] ?? json['tipo_servicio_id']) ?? '-',
            tipoServicioNombre:
                _stringOrNull(json['tipoServicioNombre'] ?? json['tipo_servicio_nombre']) ?? '-',
            precioUsdSnapshot: _toDouble(
              json['precioUsdSnapshot'] ?? json['precio_usd_snapshot'] ?? json['precioUsd'] ?? 0,
            ),
            aprobado: _toBool(json['aprobado']),
            fechaAprobacion: _stringOrNull(json['fechaAprobacion'] ?? json['fecha_aprobacion']),
            createdAt: _stringOrNull(json['createdAt'] ?? json['created_at']),
          ),
        )
        .toList();

    final metaJson = _asMap(root['meta']);
    final computedAprobados = items.where((item) => item.aprobado).length;
    final totalItems = _toInt(metaJson['totalItems']) ?? items.length;
    final aprobados = _toInt(metaJson['aprobados']) ?? computedAprobados;
    final pendientes = _toInt(metaJson['pendientes']) ?? (totalItems - aprobados);
    final subtotalUsd =
        _toDouble(metaJson['subtotalUsdTotal'] ?? metaJson['subtotal_usd_total'] ?? 0);

    return LiquidacionItemsResponse(
      liquidacionId: liquidacionIdResponse,
      items: items,
      meta: LiquidacionItemsMeta(
        totalItems: totalItems,
        aprobados: aprobados,
        pendientes: pendientes < 0 ? 0 : pendientes,
        subtotalUsdTotal: subtotalUsd,
      ),
    );
  }

  @override
  Future<List<LiquidacionCatalogoItem>> fetchTiposSalida() async {
    final payload = await _httpClient.getJson('/tipos-salida');
    return _mapCatalogItems(payload);
  }

  @override
  Future<List<LiquidacionCatalogoItem>> fetchTiposServicio() async {
    final payload = await _httpClient.getJson('/tipos-servicio');
    return _mapCatalogItems(payload);
  }

  @override
  Future<void> createLiquidacion({required CreateLiquidacionInput input}) async {
    final servicioId = input.servicioId.trim();
    final km = input.km;
    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'servicio_id': servicioId, 'km': km},
      <String, dynamic>{'servicioId': servicioId, 'km': km},
    ];

    await _sendWithFallback(
      candidates,
      (body) => _httpClient.postJson('/liquidaciones', body: body),
    );
  }

  @override
  Future<void> updateLiquidacion({required UpdateLiquidacionInput input}) async {
    final liquidacionId = input.liquidacionId.trim();
    final tipoSalidaId = input.tipoSalidaId.trim();
    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'tipo_salida_id': tipoSalidaId},
      <String, dynamic>{'tipoSalidaId': tipoSalidaId},
    ];

    await _sendWithFallback(
      candidates,
      (body) => _httpClient.patchJson('/liquidaciones/$liquidacionId', body: body),
    );
  }

  @override
  Future<void> approveLiquidacion(String liquidacionId) async {
    await _httpClient.patchJson('/liquidaciones/${liquidacionId.trim()}/aprobar');
  }

  @override
  Future<void> addLiquidacionItem({required AddLiquidacionItemInput input}) async {
    final liquidacionId = input.liquidacionId.trim();
    final tipoServicioId = input.tipoServicioId.trim();
    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'tipo_servicio_id': tipoServicioId},
      <String, dynamic>{'tipoServicioId': tipoServicioId},
    ];

    await _sendWithFallback(
      candidates,
      (body) => _httpClient.postJson('/liquidaciones/$liquidacionId/items', body: body),
    );
  }

  @override
  Future<void> approveLiquidacionItem({required ApproveLiquidacionItemInput input}) async {
    final liquidacionId = input.liquidacionId.trim();
    final itemId = input.itemId.trim();
    await _httpClient.patchJson('/liquidaciones/$liquidacionId/items/$itemId/aprobar');
  }

  @override
  Future<void> deleteLiquidacionItem({required DeleteLiquidacionItemInput input}) async {
    final liquidacionId = input.liquidacionId.trim();
    final itemId = input.itemId.trim();
    await _httpClient.deleteJson('/liquidaciones/$liquidacionId/items/$itemId');
  }

  Future<void> _sendWithFallback(
    List<Map<String, dynamic>> candidates,
    Future<dynamic> Function(Map<String, dynamic> body) sender,
  ) async {
    AppFailure? lastFailure;
    for (final body in candidates) {
      try {
        await sender(body);
        return;
      } on AppFailure catch (error) {
        if (error.statusCode == 400 || error.statusCode == 422) {
          lastFailure = error;
          continue;
        }
        rethrow;
      }
    }

    throw lastFailure ?? const AppFailure('No se pudo completar la operacion de liquidacion');
  }

  List<LiquidacionCatalogoItem> _mapCatalogItems(dynamic payload) {
    final entries = _extractItems(payload);
    final output = <LiquidacionCatalogoItem>[];
    final seenIds = <String>{};

    for (final raw in entries) {
      final json = _asMap(raw);
      final id = _stringOrNull(json['id']);
      if (id == null || seenIds.contains(id)) {
        continue;
      }

      final nombre = _stringOrNull(
            json['nombre'] ?? json['descripcion'] ?? json['detalle'] ?? json['tipo'],
          ) ??
          id;
      seenIds.add(id);
      output.add(LiquidacionCatalogoItem(id: id, nombre: nombre));
    }

    output.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return output;
  }

  List<dynamic> _extractItems(dynamic payload) {
    if (payload is List) {
      return payload;
    }

    final root = _asMap(payload);
    if (root.isEmpty) {
      return const <dynamic>[];
    }

    const keys = <String>[
      'items',
      'data',
      'results',
      'rows',
      'tiposSalida',
      'tiposServicio',
    ];

    for (final key in keys) {
      final value = root[key];
      if (value is List) {
        return value;
      }
      if (value is Map) {
        final nested = _asMap(value);
        for (final nestedKey in keys) {
          final nestedValue = nested[nestedKey];
          if (nestedValue is List) {
            return nestedValue;
          }
        }
      }
    }

    if (root.containsKey('id')) {
      return <dynamic>[root];
    }

    return const <dynamic>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'aprobada' ||
          normalized == 'aprobado' ||
          normalized == 'true' ||
          normalized == 'approved';
    }
    return false;
  }

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }
}
