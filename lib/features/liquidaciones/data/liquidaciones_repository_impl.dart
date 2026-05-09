import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesRepositoryImpl implements LiquidacionesRepository {
  static const bool enableItemsGetEndpoint = bool.fromEnvironment(
    'LIQUIDACIONES_ENABLE_ITEMS_GET',
    defaultValue: true,
  );

  LiquidacionesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    final payload = await _fetchLiquidacionesPayload(query: query);

    final result = PagedResult<LiquidacionItem>.fromDynamic(
      payload,
      (json) {
        final root = _asMap(json);
        final servicioNode = _asMap(json['servicio']);
        final tecnicoNode = _asMap(json['tecnico']);
        final tipoSalidaNode = _asMap(json['tipoSalida']);

        final precioTipoSalida = _toDouble(
          root['tipoSalidaPrecioUsd'] ??
              root['tipo_salida_precio_usd'] ??
              tipoSalidaNode['precioUsd'] ??
              tipoSalidaNode['precio_usd'],
        );
        final precioKmSnapshot = _toDouble(
          root['precioKmUsdSnapshot'] ??
              root['precio_km_usd_snapshot'] ??
              root['precioKmUsd'] ??
              root['precio_km_usd'],
        );

        return LiquidacionItem(
          id: _stringOrNull(root['id'] ?? root['liquidacionId'] ?? root['liquidacion_id']) ?? '-',
          servicioId: _stringOrNull(
                root['servicioId'] ?? root['servicio_id'] ?? servicioNode['id'],
              ) ??
              '-',
          servicioCanal: _stringOrNull(servicioNode['canal'] ?? root['canal']) ?? '-',
          tecnicoId: _stringOrNull(root['tecnicoId'] ?? root['tecnico_id'] ?? tecnicoNode['id']),
          tecnicoNombre: _stringOrNull(
            root['tecnicoNombre'] ??
                root['tecnico_nombre'] ??
                tecnicoNode['fullName'] ??
                tecnicoNode['full_name'] ??
                tecnicoNode['nombre'],
          ),
          tecnicoEmail: _stringOrNull(
            root['tecnicoEmail'] ??
                root['tecnico_email'] ??
                tecnicoNode['email'],
          ),
          tipoSalidaId: _stringOrNull(
            root['tipoSalidaId'] ?? root['tipo_salida_id'] ?? tipoSalidaNode['id'],
          ),
          tipoSalidaNombre: _stringOrNull(
            root['tipoSalidaNombre'] ??
                root['tipo_salida_nombre'] ??
                tipoSalidaNode['nombre'],
          ),
          tipoSalidaPrecioUsd: precioTipoSalida,
          km: _toInt(root['km']) ?? 0,
          precioKmUsdSnapshot: precioKmSnapshot,
          aprobada: _toBool(root['aprobado'] ?? root['aprobada']),
          fechaAprobacion: _stringOrNull(
            root['fechaAprobacion'] ?? root['fecha_aprobacion'],
          ),
          createdAt: _stringOrNull(root['createdAt'] ?? root['created_at']),
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
  Future<LiquidacionItemsResponse?> fetchLiquidacionItems(String liquidacionId) async {
    if (!enableItemsGetEndpoint) {
      return null;
    }

    dynamic payload;
    try {
      payload = await _httpClient.getJson('/liquidaciones/${liquidacionId.trim()}/items');
    } on AppFailure catch (error) {
      if (_isItemsEndpointUnavailable(error)) {
        return null;
      }
      rethrow;
    }

    final root = _asMap(payload);
    final dataNode = _asMap(root['data']);
    final source = dataNode.isEmpty ? root : dataNode;

    final liquidacionIdResponse =
        _stringOrNull(source['liquidacionId'] ?? source['liquidacion_id']) ?? liquidacionId;

    final itemsRaw = source['items'];
    final itemsList = itemsRaw is List ? itemsRaw : const <dynamic>[];
    final items = itemsList
        .map(_asMap)
        .map((json) => _mapLiquidacionItemDetalle(json))
        .whereType<LiquidacionItemDetalle>()
        .toList();

    final metaJson = _asMap(source['meta']);
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
      remoteEnabled: true,
    );
  }

  @override
  Future<List<TipoSalidaCatalogoItem>> fetchTiposSalida() async {
    final payload = await _httpClient.getJson('/tipos-salida');
    final entries = _extractItems(payload);
    final output = <TipoSalidaCatalogoItem>[];
    final seenIds = <String>{};

    for (final raw in entries) {
      final json = _asMap(raw);
      final id = _stringOrNull(json['id']);
      if (id == null || seenIds.contains(id)) {
        continue;
      }

      output.add(
        TipoSalidaCatalogoItem(
          id: id,
          nombre: _stringOrNull(json['nombre']) ?? id,
          kmHasta: _toInt(json['kmHasta'] ?? json['km_hasta']),
          precioUsd: _toDouble(json['precioUsd'] ?? json['precio_usd']),
          activo: _toBool(json['activo'] ?? true),
        ),
      );
      seenIds.add(id);
    }

    output.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return output;
  }

  @override
  Future<List<TipoServicioCatalogoItem>> fetchTiposServicio() async {
    final payload = await _httpClient.getJson('/tipos-servicio');
    final entries = _extractItems(payload);
    final output = <TipoServicioCatalogoItem>[];
    final seenIds = <String>{};

    for (final raw in entries) {
      final json = _asMap(raw);
      final id = _stringOrNull(json['id']);
      if (id == null || seenIds.contains(id)) {
        continue;
      }

      output.add(
        TipoServicioCatalogoItem(
          id: id,
          nombre: _stringOrNull(json['nombre']) ?? id,
          precioUsd: _toDouble(json['precioUsd'] ?? json['precio_usd']),
          activo: _toBool(json['activo'] ?? true),
        ),
      );
      seenIds.add(id);
    }

    output.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return output;
  }

  @override
  Future<void> createLiquidacion({required CreateLiquidacionInput input}) async {
    final servicioId = input.servicioId.trim();
    final km = input.km;
    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'servicio_id': servicioId, 'km': km},
      <String, dynamic>{'servicioId': servicioId, 'km': km},
    ];

    await _sendWithFallback<dynamic>(
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

    await _sendWithFallback<dynamic>(
      candidates,
      (body) => _httpClient.patchJson('/liquidaciones/$liquidacionId', body: body),
    );
  }

  @override
  Future<void> approveLiquidacion(String liquidacionId) async {
    await _httpClient.patchJson('/liquidaciones/${liquidacionId.trim()}/aprobar');
  }

  @override
  Future<LiquidacionItemDetalle?> addLiquidacionItem({
    required AddLiquidacionItemInput input,
  }) async {
    final liquidacionId = input.liquidacionId.trim();
    final tipoServicioId = input.tipoServicioId.trim();
    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'tipo_servicio_id': tipoServicioId},
      <String, dynamic>{'tipoServicioId': tipoServicioId},
    ];

    final payload = await _sendWithFallback<dynamic>(
      candidates,
      (body) => _httpClient.postJson('/liquidaciones/$liquidacionId/items', body: body),
    );

    final root = _asMap(payload);
    final direct = _mapLiquidacionItemDetalle(
      root,
      fallbackTipoServicioId: tipoServicioId,
    );
    if (direct != null) {
      return direct;
    }

    final fromData = _mapLiquidacionItemDetalle(
      _asMap(root['data']),
      fallbackTipoServicioId: tipoServicioId,
    );
    if (fromData != null) {
      return fromData;
    }

    final fromItem = _mapLiquidacionItemDetalle(
      _asMap(root['item']),
      fallbackTipoServicioId: tipoServicioId,
    );
    if (fromItem != null) {
      return fromItem;
    }

    return null;
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

  @override
  Future<void> createTipoSalida({required CreateTipoSalidaInput input}) async {
    final body = <String, dynamic>{
      'nombre': input.nombre.trim(),
      'precioUsd': input.precioUsd,
      if (input.kmHasta != null) 'kmHasta': input.kmHasta,
    };
    await _httpClient.postJson('/tipos-salida', body: body);
  }

  @override
  Future<void> updateTipoSalida({required UpdateTipoSalidaInput input}) async {
    final body = <String, dynamic>{
      if (input.nombre != null) 'nombre': input.nombre!.trim(),
      if (input.kmHasta != null) 'kmHasta': input.kmHasta,
      if (input.precioUsd != null) 'precioUsd': input.precioUsd,
      if (input.activo != null) 'activo': input.activo,
    };
    await _httpClient.patchJson('/tipos-salida/${input.id.trim()}', body: body);
  }

  @override
  Future<void> createTipoServicio({required CreateTipoServicioInput input}) async {
    final body = <String, dynamic>{
      'nombre': input.nombre.trim(),
      'precioUsd': input.precioUsd,
    };
    await _httpClient.postJson('/tipos-servicio', body: body);
  }

  @override
  Future<void> updateTipoServicio({required UpdateTipoServicioInput input}) async {
    final body = <String, dynamic>{
      if (input.nombre != null) 'nombre': input.nombre!.trim(),
      if (input.precioUsd != null) 'precioUsd': input.precioUsd,
      if (input.activo != null) 'activo': input.activo,
    };
    await _httpClient.patchJson('/tipos-servicio/${input.id.trim()}', body: body);
  }

  Future<dynamic> _fetchLiquidacionesPayload({required LiquidacionesQuery query}) async {
    final pagedParams = <String, String>{
      'page': query.page.toString(),
      'limit': query.limit.toString(),
      if (_stringOrNull(query.tecnicoId) != null) 'tecnicoId': query.tecnicoId!.trim(),
      if (query.aprobado != null) 'aprobado': query.aprobado! ? 'true' : 'false',
    };

    try {
      return await _httpClient.getJson('/liquidaciones', queryParameters: pagedParams);
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }

      final fallbackParams = <String, String>{
        if (_stringOrNull(query.tecnicoId) != null) 'tecnicoId': query.tecnicoId!.trim(),
        if (query.aprobado != null) 'aprobado': query.aprobado! ? 'true' : 'false',
      };
      return _httpClient.getJson('/liquidaciones', queryParameters: fallbackParams);
    }
  }

  bool _isItemsEndpointUnavailable(AppFailure error) {
    final status = error.statusCode;
    if (status == 404 || status == 405 || status == 501) {
      return true;
    }

    final message = error.message.toLowerCase();
    return message.contains('cannot get') && message.contains('/items');
  }

  LiquidacionItemDetalle? _mapLiquidacionItemDetalle(
    Map<String, dynamic> json, {
    String? fallbackTipoServicioId,
    String? fallbackTipoServicioNombre,
    double? fallbackPrecioUsd,
  }) {
    if (json.isEmpty) {
      return null;
    }

    final tipoServicioNode = _asMap(json['tipoServicio']);
    final id = _stringOrNull(json['id']);
    if (id == null) {
      return null;
    }

    return LiquidacionItemDetalle(
      id: id,
      tipoServicioId: _stringOrNull(
            json['tipoServicioId'] ??
                json['tipo_servicio_id'] ??
                tipoServicioNode['id'],
          ) ??
          fallbackTipoServicioId ??
          '-',
      tipoServicioNombre: _stringOrNull(
            json['tipoServicioNombre'] ??
                json['tipo_servicio_nombre'] ??
                json['nombreSnapshot'] ??
                json['nombre_snapshot'] ??
                tipoServicioNode['nombre'],
          ) ??
          fallbackTipoServicioNombre ??
          '-',
      precioUsdSnapshot: _toDouble(
        json['precioUsdSnapshot'] ??
            json['precio_usd_snapshot'] ??
            json['precioUsd'] ??
            json['precio_usd'] ??
            tipoServicioNode['precioUsd'] ??
            tipoServicioNode['precio_usd'] ??
            fallbackPrecioUsd,
      ),
      aprobado: _toBool(json['aprobado'] ?? json['aprobada']),
      fechaAprobacion: _stringOrNull(json['fechaAprobacion'] ?? json['fecha_aprobacion']),
      createdAt: _stringOrNull(json['createdAt'] ?? json['created_at']),
    );
  }

  Future<T> _sendWithFallback<T>(
    List<Map<String, dynamic>> candidates,
    Future<T> Function(Map<String, dynamic> body) sender,
  ) async {
    AppFailure? lastFailure;
    for (final body in candidates) {
      try {
        return await sender(body);
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
    if (value is bool) {
      return value ? 1 : 0;
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
    if (value is bool) {
      return value ? 1 : 0;
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
          normalized == 'si' ||
          normalized == 'yes' ||
          normalized == 'true' ||
          normalized == 'approved';
    }
    if (value is num) {
      return value > 0;
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
