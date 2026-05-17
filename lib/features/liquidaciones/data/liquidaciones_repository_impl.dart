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
    final normalizedPayload = _normalizeLiquidacionesPayload(payload);

    final result = PagedResult<LiquidacionItem>.fromDynamic(
      normalizedPayload,
      (json) {
        final root = _asMap(json);
        final liquidacionNode = _asMap(root['liquidacion']);
        final source = liquidacionNode.isEmpty ? root : liquidacionNode;
        final servicioNode = _asMap(source['servicio']);
        final tecnicoNode = _asMap(source['tecnico']);
        final tipoSalidaNode = _asMap(source['tipoSalida'] ?? source['tipo_salida']);

        final precioTipoSalida = _toDouble(
          source['tipoSalidaPrecioUsd'] ??
              source['tipo_salida_precio_usd'] ??
              tipoSalidaNode['precioUsd'] ??
              tipoSalidaNode['precio_usd'],
        );
        final precioKmSnapshot = _toDouble(
          source['precioKmUsdSnapshot'] ??
              source['precio_km_usd_snapshot'] ??
              source['precioKmUsd'] ??
              source['precio_km_usd'],
        );

        return LiquidacionItem(
          id: _stringOrNull(source['id'] ?? source['liquidacionId'] ?? source['liquidacion_id']) ?? '-',
          servicioId: _stringOrNull(
                source['servicioId'] ?? source['servicio_id'] ?? servicioNode['id'],
              ) ??
              '-',
          servicioCanal: _stringOrNull(servicioNode['canal'] ?? source['canal']) ?? '-',
          tecnicoId: _stringOrNull(source['tecnicoId'] ?? source['tecnico_id'] ?? tecnicoNode['id']),
          tecnicoNombre: _stringOrNull(
            source['tecnicoNombre'] ??
                source['tecnico_nombre'] ??
                tecnicoNode['fullName'] ??
                tecnicoNode['full_name'] ??
                tecnicoNode['nombre'],
          ),
          tecnicoEmail: _stringOrNull(
            source['tecnicoEmail'] ??
                source['tecnico_email'] ??
                tecnicoNode['email'],
          ),
          tipoSalidaId: _stringOrNull(
            source['tipoSalidaId'] ?? source['tipo_salida_id'] ?? tipoSalidaNode['id'],
          ),
          tipoSalidaNombre: _stringOrNull(
            source['tipoSalidaNombre'] ??
                source['tipo_salida_nombre'] ??
                tipoSalidaNode['nombre'],
          ),
          tipoSalidaPrecioUsd: precioTipoSalida,
          km: _toInt(source['km']) ?? 0,
          precioKmUsdSnapshot: precioKmSnapshot,
          aprobada: _toBool(source['aprobado'] ?? source['aprobada']),
          fechaAprobacion: _stringOrNull(
            source['fechaAprobacion'] ?? source['fecha_aprobacion'],
          ),
          createdAt: _stringOrNull(source['createdAt'] ?? source['created_at']),
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
  Future<PagedResult<LiquidacionPendienteItem>> fetchLiquidacionesPendientes({
    required LiquidacionesPendientesQuery query,
  }) async {
    final payload = await _fetchPendientesPayload(query: query);
    final normalizedPayload = _normalizePendientesPayload(payload);

    final result = PagedResult<LiquidacionPendienteItem>.fromDynamic(
      normalizedPayload,
      (json) {
        final root = _asMap(json);
        final servicioNode = _asMap(root['servicio']);
        final tecnicoNode = _asMap(root['tecnico'] ?? servicioNode['tecnico']);
        final clienteNode = _asMap(root['cliente'] ?? servicioNode['cliente']);
        final source = servicioNode.isEmpty ? root : servicioNode;

        return LiquidacionPendienteItem(
          servicioId: _stringOrNull(
                root['servicioId'] ??
                    root['servicio_id'] ??
                    source['servicioId'] ??
                    source['servicio_id'] ??
                    source['id'],
              ) ??
              '-',
          servicioCanal: _stringOrNull(
                root['canal'] ?? source['canal'],
              ) ??
              '-',
          kmSugerido: _toInt(
            root['km'] ??
                root['kmSugerido'] ??
                root['km_sugerido'] ??
                source['km'] ??
                source['kmSugerido'] ??
                source['km_sugerido'],
          ),
          tecnicoId: _stringOrNull(
            root['tecnicoId'] ??
                root['tecnico_id'] ??
                source['tecnicoId'] ??
                source['tecnico_id'] ??
                tecnicoNode['id'],
          ),
          tecnicoNombre: _stringOrNull(
            root['tecnicoNombre'] ??
                root['tecnico_nombre'] ??
                source['tecnicoNombre'] ??
                source['tecnico_nombre'] ??
                tecnicoNode['fullName'] ??
                tecnicoNode['full_name'] ??
                tecnicoNode['nombre'],
          ),
          tecnicoEmail: _stringOrNull(
            root['tecnicoEmail'] ??
                root['tecnico_email'] ??
                source['tecnicoEmail'] ??
                source['tecnico_email'] ??
                tecnicoNode['email'],
          ),
          clienteNombre: _stringOrNull(
            root['clienteNombre'] ??
                root['cliente_nombre'] ??
                source['clienteNombre'] ??
                source['cliente_nombre'] ??
                clienteNode['nombre'],
          ),
          fechaHoraServicio: _stringOrNull(
            root['fechaHoraServicio'] ??
                root['fecha_hora_servicio'] ??
                source['fechaHoraServicio'] ??
                source['fecha_hora_servicio'] ??
                source['createdAt'] ??
                source['created_at'],
          ),
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
        ? <LiquidacionPendienteItem>[]
        : result.items.sublist(
            start,
            end > result.items.length ? result.items.length : end,
          );

    return PagedResult<LiquidacionPendienteItem>(
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
    if (servicioId.isEmpty) {
      throw const AppFailure('Servicio invalido para crear liquidacion');
    }

    if (input.km <= 0) {
      throw const AppFailure('El KM debe ser mayor a 0 para crear la liquidacion');
    }

    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{
        'servicio_id': servicioId,
        'km': input.km,
      },
      <String, dynamic>{
        'servicioId': servicioId,
        'km': input.km,
      },
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
    AppFailure? lastFailure;

    for (final params in _buildLiquidacionesQueryCandidates(query)) {
      try {
        return await _httpClient.getJson('/liquidaciones', queryParameters: params);
      } on AppFailure catch (error) {
        if (error.statusCode != 400) {
          rethrow;
        }
        lastFailure = error;
      }
    }

    throw lastFailure ?? const AppFailure('No se pudo obtener liquidaciones');
  }

  Future<dynamic> _fetchPendientesPayload({
    required LiquidacionesPendientesQuery query,
  }) async {
    AppFailure? lastFailure;

    for (final params in _buildPendientesQueryCandidates(query)) {
      try {
        return await _httpClient.getJson('/liquidaciones/pendientes', queryParameters: params);
      } on AppFailure catch (error) {
        if (error.statusCode != 400) {
          rethrow;
        }
        lastFailure = error;
      }
    }

    throw lastFailure ?? const AppFailure('No se pudo obtener pendientes de liquidacion');
  }

  List<Map<String, String>> _buildLiquidacionesQueryCandidates(
    LiquidacionesQuery query,
  ) {
    final tecnicoId = _stringOrNull(query.tecnicoId);
    final aprobado = query.aprobado;
    final aprobadoValue = aprobado == null ? null : (aprobado ? 'true' : 'false');
    final tecnicoKeys = tecnicoId == null
        ? const <String?>[null]
        : const <String?>['tecnicoId', 'tecnico_id'];
    final aprobadoKeys = aprobadoValue == null
        ? const <String?>[null]
        : const <String?>['aprobado'];

    final signatures = <String>{};
    final candidates = <Map<String, String>>[];

    void addCandidate({
      required bool includePagination,
      required String? tecnicoKey,
      required String? aprobadoKey,
    }) {
      final params = <String, String>{
        if (tecnicoKey != null && tecnicoId != null) tecnicoKey: tecnicoId,
        if (aprobadoKey != null && aprobadoValue != null) aprobadoKey: aprobadoValue,
        if (includePagination) 'page': query.page.toString(),
        if (includePagination) 'limit': query.limit.toString(),
      };

      final signature = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
      if (signatures.add(signature)) {
        candidates.add(params);
      }
    }

    for (final tecnicoKey in tecnicoKeys) {
      for (final aprobadoKey in aprobadoKeys) {
        addCandidate(
          includePagination: true,
          tecnicoKey: tecnicoKey,
          aprobadoKey: aprobadoKey,
        );
        addCandidate(
          includePagination: false,
          tecnicoKey: tecnicoKey,
          aprobadoKey: aprobadoKey,
        );
      }
    }

    return candidates;
  }

  List<Map<String, String>> _buildPendientesQueryCandidates(
    LiquidacionesPendientesQuery query,
  ) {
    final tecnicoId = _stringOrNull(query.tecnicoId);
    final tecnicoKeys = tecnicoId == null
        ? const <String?>[null]
        : const <String?>['tecnicoId', 'tecnico_id'];

    final signatures = <String>{};
    final candidates = <Map<String, String>>[];

    void addCandidate({
      required bool includePagination,
      required String? tecnicoKey,
    }) {
      final params = <String, String>{
        if (tecnicoKey != null && tecnicoId != null) tecnicoKey: tecnicoId,
        if (includePagination) 'page': query.page.toString(),
        if (includePagination) 'limit': query.limit.toString(),
      };

      final signature = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
      if (signatures.add(signature)) {
        candidates.add(params);
      }
    }

    for (final tecnicoKey in tecnicoKeys) {
      addCandidate(includePagination: true, tecnicoKey: tecnicoKey);
      addCandidate(includePagination: false, tecnicoKey: tecnicoKey);
    }

    return candidates;
  }

  dynamic _normalizeLiquidacionesPayload(dynamic payload) {
    if (payload is List) {
      return <String, dynamic>{'items': payload};
    }

    final root = _asMap(payload);
    if (root.isEmpty) {
      return payload;
    }

    final directItems = _extractLiquidacionesItems(root);
    if (directItems != null) {
      return <String, dynamic>{
        'items': directItems,
        if (root['meta'] is Map) 'meta': root['meta'],
        if (root['pagination'] is Map) 'pagination': root['pagination'],
        if (root['page'] != null) 'page': root['page'],
        if (root['limit'] != null) 'limit': root['limit'],
        if (root['pageSize'] != null) 'pageSize': root['pageSize'],
        if (root['total'] != null) 'total': root['total'],
        if (root['count'] != null) 'count': root['count'],
        if (root['totalItems'] != null) 'totalItems': root['totalItems'],
      };
    }

    final dataNode = _asMap(root['data']);
    if (dataNode.isEmpty) {
      return payload;
    }

    final dataItems = _extractLiquidacionesItems(dataNode);
    if (dataItems == null) {
      return payload;
    }

    return <String, dynamic>{
      'items': dataItems,
      if (dataNode['meta'] is Map) 'meta': dataNode['meta'] else if (root['meta'] is Map) 'meta': root['meta'],
      if (dataNode['pagination'] is Map)
        'pagination': dataNode['pagination']
      else if (root['pagination'] is Map)
        'pagination': root['pagination'],
      if (dataNode['page'] != null) 'page': dataNode['page'] else if (root['page'] != null) 'page': root['page'],
      if (dataNode['limit'] != null) 'limit': dataNode['limit'] else if (root['limit'] != null) 'limit': root['limit'],
      if (dataNode['pageSize'] != null)
        'pageSize': dataNode['pageSize']
      else if (root['pageSize'] != null)
        'pageSize': root['pageSize'],
      if (dataNode['total'] != null) 'total': dataNode['total'] else if (root['total'] != null) 'total': root['total'],
      if (dataNode['count'] != null) 'count': dataNode['count'] else if (root['count'] != null) 'count': root['count'],
      if (dataNode['totalItems'] != null)
        'totalItems': dataNode['totalItems']
      else if (root['totalItems'] != null)
        'totalItems': root['totalItems'],
    };
  }

  dynamic _normalizePendientesPayload(dynamic payload) {
    if (payload is List) {
      return <String, dynamic>{'items': payload};
    }

    final root = _asMap(payload);
    if (root.isEmpty) {
      return payload;
    }

    final directItems = _extractPendientesItems(root);
    if (directItems != null) {
      return <String, dynamic>{
        'items': directItems,
        if (root['meta'] is Map) 'meta': root['meta'],
        if (root['pagination'] is Map) 'pagination': root['pagination'],
        if (root['page'] != null) 'page': root['page'],
        if (root['limit'] != null) 'limit': root['limit'],
        if (root['pageSize'] != null) 'pageSize': root['pageSize'],
        if (root['total'] != null) 'total': root['total'],
        if (root['count'] != null) 'count': root['count'],
        if (root['totalItems'] != null) 'totalItems': root['totalItems'],
      };
    }

    final dataNode = _asMap(root['data']);
    if (dataNode.isEmpty) {
      return payload;
    }

    final dataItems = _extractPendientesItems(dataNode);
    if (dataItems == null) {
      return payload;
    }

    return <String, dynamic>{
      'items': dataItems,
      if (dataNode['meta'] is Map) 'meta': dataNode['meta'] else if (root['meta'] is Map) 'meta': root['meta'],
      if (dataNode['pagination'] is Map)
        'pagination': dataNode['pagination']
      else if (root['pagination'] is Map)
        'pagination': root['pagination'],
      if (dataNode['page'] != null) 'page': dataNode['page'] else if (root['page'] != null) 'page': root['page'],
      if (dataNode['limit'] != null) 'limit': dataNode['limit'] else if (root['limit'] != null) 'limit': root['limit'],
      if (dataNode['pageSize'] != null)
        'pageSize': dataNode['pageSize']
      else if (root['pageSize'] != null)
        'pageSize': root['pageSize'],
      if (dataNode['total'] != null) 'total': dataNode['total'] else if (root['total'] != null) 'total': root['total'],
      if (dataNode['count'] != null) 'count': dataNode['count'] else if (root['count'] != null) 'count': root['count'],
      if (dataNode['totalItems'] != null)
        'totalItems': dataNode['totalItems']
      else if (root['totalItems'] != null)
        'totalItems': root['totalItems'],
    };
  }

  List<dynamic>? _extractLiquidacionesItems(Map<String, dynamic> source) {
    const keys = <String>[
      'liquidaciones',
      'items',
      'results',
      'rows',
      'data',
    ];

    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value;
      }
    }

    return null;
  }

  List<dynamic>? _extractPendientesItems(Map<String, dynamic> source) {
    const keys = <String>[
      'pendientes',
      'servicios',
      'items',
      'results',
      'rows',
      'data',
    ];

    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value;
      }
    }

    return null;
  }

  bool _isItemsEndpointUnavailable(AppFailure error) {
    final status = error.statusCode;
    if (status == 404 || status == 501) {
      return true;
    }

    if (status != null) {
      return false;
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
      'tipos_salida',
      'tiposServicio',
      'tipos_servicio',
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
