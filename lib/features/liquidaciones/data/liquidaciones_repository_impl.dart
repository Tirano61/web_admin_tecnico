import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesRepositoryImpl implements LiquidacionesRepository {
  static const bool enableItemsGetEndpoint = bool.fromEnvironment(
    'LIQUIDACIONES_ENABLE_ITEMS_GET',
    defaultValue: true,
  );

  // El flujo de pago no recibe cliente del backend: se hidrata con
  // GET /servicios/:id. Apagable si el fan-out resulta caro en produccion.
  static const bool enableClienteHydration = bool.fromEnvironment(
    'LIQUIDACIONES_ENABLE_PREVIEW_CLIENTE_HYDRATION',
    defaultValue: true,
  );

  static const int _liquidacionLookupPageSize = 100;
  static const int _maxLiquidacionLookupPages = 5;

  // El navegador limita ~6 conexiones por host; mas concurrencia no acelera.
  static const int _hydrationConcurrency = 6;

  LiquidacionesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  // Cache por instancia de repositorio (vive lo que vive la pagina). Evita
  // repetir el fan-out cuando confirmarResumen() vuelve a pedir el preview.
  final Map<String, _ServicioResumen> _servicioResumenCache =
      <String, _ServicioResumen>{};
  final Map<String, Future<_ServicioResumen?>> _servicioResumenInFlight =
      <String, Future<_ServicioResumen?>>{};

  // id de liquidacion -> datos que solo devuelve GET /liquidaciones.
  final Map<String, Map<String, _LiquidacionResumen>>
      _liquidacionResumenPorTecnico = <String, Map<String, _LiquidacionResumen>>{};

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
        final rootServicioNode = _asMap(root['servicio']);
        final servicioNode = _asMap(source['servicio']);
        final resolvedServicioNode =
            servicioNode.isNotEmpty ? servicioNode : rootServicioNode;
        final servicioCanal = _stringOrNull(
          resolvedServicioNode['canal'] ??
              source['canal'] ??
              source['servicioCanal'] ??
              source['servicio_canal'] ??
              source['canalServicio'] ??
              source['canal_servicio'],
        );
        final rootTecnicoNode = _asMap(root['tecnico']);
        final tecnicoNode = _asMap(source['tecnico']);
        final resolvedTecnicoNode =
            tecnicoNode.isNotEmpty ? tecnicoNode : rootTecnicoNode;
        final rootClienteNode = _asMap(root['cliente']);
        final sourceClienteNode = _asMap(source['cliente']);
        final servicioClienteNode = _asMap(resolvedServicioNode['cliente']);
        final clienteNode = sourceClienteNode.isNotEmpty
            ? sourceClienteNode
            : (servicioClienteNode.isNotEmpty ? servicioClienteNode : rootClienteNode);
        final clienteRaw =
          source['cliente'] ?? resolvedServicioNode['cliente'] ?? root['cliente'];
        final clienteTextoPlano = clienteRaw is String && !_looksLikeUuid(clienteRaw)
          ? clienteRaw
          : null;
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
                source['servicioId'] ??
                source['servicio_id'] ??
                resolvedServicioNode['id'] ??
                root['servicioId'] ??
                root['servicio_id'],
              ) ??
              '-',
          servicioCanal: servicioCanal ?? 'campo',
              tecnicoId: _stringOrNull(
            source['tecnicoId'] ??
                source['tecnico_id'] ??
                resolvedTecnicoNode['id'] ??
                root['tecnicoId'] ??
                root['tecnico_id'],
              ),
          tecnicoNombre: _stringOrNull(
            source['tecnicoNombre'] ??
                source['tecnico_nombre'] ??
                resolvedTecnicoNode['fullName'] ??
                resolvedTecnicoNode['full_name'] ??
                resolvedTecnicoNode['nombre'] ??
                root['tecnicoNombre'] ??
                root['tecnico_nombre'],
          ),
          tecnicoEmail: _stringOrNull(
            source['tecnicoEmail'] ??
                source['tecnico_email'] ??
                resolvedTecnicoNode['email'] ??
                root['tecnicoEmail'] ??
                root['tecnico_email'],
          ),
          clienteNombre: _stringOrNull(
            source['clienteNombre'] ??
                source['cliente_nombre'] ??
                resolvedServicioNode['clienteNombre'] ??
                resolvedServicioNode['cliente_nombre'] ??
                root['clienteNombre'] ??
                root['cliente_nombre'] ??
                clienteNode['nombre'] ??
                clienteNode['fullName'] ??
                clienteNode['full_name'] ??
                clienteNode['razonSocial'] ??
                clienteNode['razon_social'] ??
                clienteTextoPlano,
          ) ??
              _searchClienteNombre(
                root,
                clienteContext: false,
                depth: 0,
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
          precioKmUsdSnapshotLegacy: precioKmSnapshot,
          aprobada: _toBool(source['aprobado'] ?? source['aprobada']),
          liquidadaPago: _toBool(
            source['liquidadaPago'] ??
                source['liquidada_pago'] ??
                source['pagada'] ??
                source['pasadaPago'] ??
                source['pasada_pago'],
          ),
          estado: _stringOrNull(
            source['estado'] ??
                source['estadoLiquidacion'] ??
                source['estado_liquidacion'],
          ),
          fechaLiquidadaPago: _stringOrNull(
            source['fechaLiquidadaPago'] ??
                source['fecha_liquidada_pago'] ??
                source['fechaPago'] ??
                source['fecha_pago'],
          ),
          fechaAprobacion: _stringOrNull(
            source['fechaAprobacion'] ?? source['fecha_aprobacion'],
          ),
          createdAt: _stringOrNull(source['createdAt'] ?? source['created_at']),
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    final hydratedItems = await _hydrateLiquidacionesFromServiciosIfNeeded(
      result.items,
    );

    if (hydratedItems.length <= query.limit) {
      return PagedResult<LiquidacionItem>(
        items: hydratedItems,
        total: result.total,
        page: result.page,
        limit: result.limit,
      );
    }

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pagedItems = start >= hydratedItems.length
        ? <LiquidacionItem>[]
        : hydratedItems.sublist(start, end > hydratedItems.length ? hydratedItems.length : end);

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
        final rootTecnicoNode = _asMap(root['tecnico']);
        final servicioTecnicoNode = _asMap(servicioNode['tecnico']);
        final tecnicoNode = rootTecnicoNode.isNotEmpty ? rootTecnicoNode : servicioTecnicoNode;
        final rootClienteNode = _asMap(root['cliente']);
        final servicioClienteNode = _asMap(servicioNode['cliente']);
        final clienteNode = rootClienteNode.isNotEmpty ? rootClienteNode : servicioClienteNode;
        final source = servicioNode.isEmpty ? root : servicioNode;
        final facturacionNode = _asMap(root['facturacion'] ?? source['facturacion']);
        final clienteRaw = root['cliente'] ?? source['cliente'];
        final clienteTextoPlano = clienteRaw is String && !_looksLikeUuid(clienteRaw)
          ? clienteRaw
          : null;

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
                root['kmCantidad'] ??
                root['km_cantidad'] ??
                source['km'] ??
                source['kmSugerido'] ??
                source['km_sugerido'] ??
                source['kmCantidad'] ??
                source['km_cantidad'] ??
                facturacionNode['kmCantidad'] ??
                facturacionNode['km_cantidad'] ??
                facturacionNode['km'],
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
          clienteNombre: _resolveClienteNombrePendiente(
            root: root,
            source: source,
            clienteNode: clienteNode,
            clienteTextoPlano: clienteTextoPlano,
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
      final hydratedItems = await _hydratePendientesFromServiciosIfNeeded(
        result.items,
      );

      return PagedResult<LiquidacionPendienteItem>(
        items: hydratedItems,
        total: result.total,
        page: result.page,
        limit: result.limit,
      );
    }

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pagedItems = start >= result.items.length
        ? <LiquidacionPendienteItem>[]
        : result.items.sublist(
            start,
            end > result.items.length ? result.items.length : end,
          );

    final hydratedPagedItems = await _hydratePendientesFromServiciosIfNeeded(
      pagedItems,
    );

    return PagedResult<LiquidacionPendienteItem>(
      items: hydratedPagedItems,
      total: result.total,
      page: query.page,
      limit: query.limit,
    );
  }

  /// Trae y cachea el resumen de un servicio. Devuelve null si el servicio no
  /// se puede leer: la hidratacion es best-effort y nunca voltea al caller.
  Future<_ServicioResumen?> _fetchServicioResumen(String servicioId) async {
    final id = servicioId.trim();
    if (id.isEmpty || id == '-') {
      return null;
    }

    final cached = _servicioResumenCache[id];
    if (cached != null) {
      return cached;
    }

    final inFlight = _servicioResumenInFlight[id];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadServicioResumen(id);
    _servicioResumenInFlight[id] = future;
    try {
      final resolved = await future;
      if (resolved != null) {
        _servicioResumenCache[id] = resolved;
      }
      return resolved;
    } finally {
      _servicioResumenInFlight.remove(id);
    }
  }

  Future<_ServicioResumen?> _loadServicioResumen(String servicioId) async {
    try {
      final payload = await _httpClient.getJson('/servicios/$servicioId');
      final root = _asMap(payload);
      final servicioNode = _asMap(root['servicio']);
      final source = servicioNode.isEmpty ? root : servicioNode;
      final clienteNode = _asMap(source['cliente'] ?? root['cliente']);
      final clienteRaw = source['cliente'] ?? root['cliente'];
      final clienteTextoPlano =
          clienteRaw is String && !_looksLikeUuid(clienteRaw) ? clienteRaw : null;
      final facturacionNode =
          _asMap(root['facturacion'] ?? source['facturacion']);

      return _ServicioResumen(
        clienteNombre: _resolveClienteNombrePendiente(
          root: root,
          source: source,
          clienteNode: clienteNode,
          clienteTextoPlano: clienteTextoPlano,
        ),
        canal: _stringOrNull(source['canal'] ?? root['canal']),
        fechaHoraServicio: _stringOrNull(
          root['fechaHoraServicio'] ??
              root['fecha_hora_servicio'] ??
              source['fechaHoraServicio'] ??
              source['fecha_hora_servicio'] ??
              source['createdAt'] ??
              source['created_at'],
        ),
        kmSugerido: _toInt(
          source['km'] ??
              source['kmCantidad'] ??
              source['km_cantidad'] ??
              root['km'] ??
              root['kmCantidad'] ??
              root['km_cantidad'] ??
              facturacionNode['kmCantidad'] ??
              facturacionNode['km_cantidad'] ??
              facturacionNode['km'],
        ),
      );
    } catch (_) {
      // Incluye ClientException (CORS / red caida en web), no solo AppFailure.
      return null;
    }
  }

  /// Fan-out con concurrencia acotada sobre las filas que necesitan hidratacion.
  Future<List<T>> _hydrateFromServicios<T>({
    required List<T> items,
    required bool Function(T item) needsHydration,
    required Future<T> Function(T item) hydrate,
  }) async {
    final pending = <int>[
      for (var index = 0; index < items.length; index++)
        if (needsHydration(items[index])) index,
    ];

    if (pending.isEmpty) {
      return items;
    }

    final output = List<T>.from(items);
    for (var start = 0; start < pending.length; start += _hydrationConcurrency) {
      final end = start + _hydrationConcurrency > pending.length
          ? pending.length
          : start + _hydrationConcurrency;
      await Future.wait(
        pending.sublist(start, end).map((index) async {
          output[index] = await hydrate(output[index]);
        }),
      );
    }

    return output;
  }

  Future<List<LiquidacionPendienteItem>> _hydratePendientesFromServiciosIfNeeded(
    List<LiquidacionPendienteItem> items,
  ) {
    return _hydrateFromServicios<LiquidacionPendienteItem>(
      items: items,
      needsHydration: _requiresServicioHydration,
      hydrate: _hydratePendienteFromServicio,
    );
  }

  Future<List<LiquidacionItem>> _hydrateLiquidacionesFromServiciosIfNeeded(
    List<LiquidacionItem> items,
  ) {
    return _hydrateFromServicios<LiquidacionItem>(
      items: items,
      needsHydration: _requiresLiquidacionServicioHydration,
      hydrate: _hydrateLiquidacionFromServicio,
    );
  }

  bool _requiresLiquidacionServicioHydration(LiquidacionItem item) {
    final missingCliente = (item.clienteNombre ?? '').trim().isEmpty;
    return missingCliente;
  }

  Future<LiquidacionItem> _hydrateLiquidacionFromServicio(
    LiquidacionItem item,
  ) async {
    final servicio = await _fetchServicioResumen(item.servicioId);
    final clienteNombre = servicio?.clienteNombre;
    if (clienteNombre == null || clienteNombre.trim().isEmpty) {
      return item;
    }

    return LiquidacionItem(
      id: item.id,
      servicioId: item.servicioId,
      servicioCanal: item.servicioCanal,
      tecnicoId: item.tecnicoId,
      tecnicoNombre: item.tecnicoNombre,
      tecnicoEmail: item.tecnicoEmail,
      clienteNombre: clienteNombre,
      tipoSalidaId: item.tipoSalidaId,
      tipoSalidaNombre: item.tipoSalidaNombre,
      tipoSalidaPrecioUsd: item.tipoSalidaPrecioUsd,
      km: item.km,
      precioKmUsdSnapshotLegacy: item.precioKmUsdSnapshotLegacy,
      aprobada: item.aprobada,
      liquidadaPago: item.liquidadaPago,
      estado: item.estado,
      fechaLiquidadaPago: item.fechaLiquidadaPago,
      fechaAprobacion: item.fechaAprobacion,
      createdAt: item.createdAt,
    );
  }

  bool _requiresServicioHydration(LiquidacionPendienteItem item) {
    final missingCliente = (item.clienteNombre ?? '').trim().isEmpty;
    final missingKm = item.kmSugerido == null;
    return missingCliente || missingKm;
  }

  Future<LiquidacionPendienteItem> _hydratePendienteFromServicio(
    LiquidacionPendienteItem item,
  ) async {
    final servicio = await _fetchServicioResumen(item.servicioId);
    if (servicio == null) {
      return item;
    }

    return LiquidacionPendienteItem(
      servicioId: item.servicioId,
      servicioCanal: servicio.canal ?? item.servicioCanal,
      kmSugerido: servicio.kmSugerido ?? item.kmSugerido,
      tecnicoId: item.tecnicoId,
      tecnicoNombre: item.tecnicoNombre,
      tecnicoEmail: item.tecnicoEmail,
      clienteNombre: servicio.clienteNombre ?? item.clienteNombre,
      fechaHoraServicio: servicio.fechaHoraServicio ?? item.fechaHoraServicio,
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
    final liquidacionNode = _asMap(source['liquidacion']);
    final tipoSalidaNode = _asMap(
      source['tipoSalida'] ??
          source['tipo_salida'] ??
          liquidacionNode['tipoSalida'] ??
          liquidacionNode['tipo_salida'],
    );
    final tipoSalidaId = _stringOrNull(
      source['tipoSalidaId'] ??
          source['tipo_salida_id'] ??
          liquidacionNode['tipoSalidaId'] ??
          liquidacionNode['tipo_salida_id'] ??
          tipoSalidaNode['id'],
    );
    final tipoSalidaNombre = _stringOrNull(
      source['tipoSalidaNombre'] ??
          source['tipo_salida_nombre'] ??
          liquidacionNode['tipoSalidaNombre'] ??
          liquidacionNode['tipo_salida_nombre'] ??
          tipoSalidaNode['nombre'],
    );

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
      tipoSalidaId: tipoSalidaId,
      tipoSalidaNombre: tipoSalidaNombre,
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
  Future<void> reopenLiquidacion({required ReopenLiquidacionInput input}) async {
    final liquidacionId = input.liquidacionId.trim();
    final motivo = input.motivo.trim();
    if (liquidacionId.isEmpty) {
      throw const AppFailure('Liquidacion invalida para reapertura');
    }
    if (motivo.isEmpty) {
      throw const AppFailure('El motivo de reapertura es obligatorio');
    }

    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'motivo': motivo},
      <String, dynamic>{'motivoReapertura': motivo},
      <String, dynamic>{'motivo_reapertura': motivo},
      <String, dynamic>{'reason': motivo},
    ];

    await _sendWithFallback<dynamic>(
      candidates,
      (body) => _httpClient.patchJson('/liquidaciones/$liquidacionId/reabrir', body: body),
    );
  }

  @override
  Future<LiquidacionReaperturasResponse> fetchLiquidacionReaperturas(String liquidacionId) async {
    final sanitizedId = liquidacionId.trim();
    if (sanitizedId.isEmpty) {
      throw const AppFailure('Liquidacion invalida para consultar reaperturas');
    }

    final payload = await _httpClient.getJson('/liquidaciones/$sanitizedId/reaperturas');
    final root = _asMap(payload);
    final dataNode = _asMap(root['data']);
    final source = dataNode.isEmpty ? root : dataNode;
    final meta = _asMap(source['meta']);

    final rawItems = source['reaperturas'];
    final entries = rawItems is List ? rawItems : const <dynamic>[];

    final items = entries.map(_asMap).map((json) {
      final id = _stringOrNull(json['id']) ?? '-';
      final motivo = _stringOrNull(json['motivo']) ?? '-';
      final fecha = _stringOrNull(json['fecha'] ?? json['createdAt'] ?? json['created_at']) ?? '-';
      return LiquidacionReaperturaItem(
        id: id,
        motivo: motivo,
        fecha: fecha,
      );
    }).toList();

    return LiquidacionReaperturasResponse(
      liquidacionId: _stringOrNull(source['liquidacionId'] ?? source['liquidacion_id']) ?? sanitizedId,
      reaperturas: items,
      total: _toInt(meta['total']) ?? items.length,
    );
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

  @override
  Future<ResumenPagoPreviewResponse> fetchResumenPagoPreview({
    required ResumenPagoPreviewQuery query,
  }) async {
    final payload = await _httpClient.getJson(
      '/liquidaciones/resumen-pago/preview',
      queryParameters: <String, String>{
        'tecnicoId': query.tecnicoId.trim(),
        'desde': query.desde.trim(),
        'hasta': query.hasta.trim(),
      },
    );

    return _mapAndHydrateResumenPagoPreview(
      payload,
      tecnicoId: query.tecnicoId,
    );
  }

  @override
  Future<ResumenPagoPreviewResponse> confirmarResumenPago({
    required ConfirmarResumenPagoInput input,
  }) async {
    final payload = await _httpClient.patchJson(
      '/liquidaciones/resumen-pago/confirmar',
      body: <String, dynamic>{
        'tecnicoId': input.tecnicoId.trim(),
        'desde': input.desde.trim(),
        'hasta': input.hasta.trim(),
        'liquidacionIds': input.liquidacionIds,
      },
    );

    // Confirmar cambia liquidadaPago a true, asi que el lookup cacheado (que
    // se armo con liquidadaPago=false) queda viejo.
    _liquidacionResumenPorTecnico.remove('${input.tecnicoId.trim()}|false');

    return _mapAndHydrateResumenPagoPreview(
      payload,
      tecnicoId: input.tecnicoId,
    );
  }

  @override
  Future<PagedResult<ResumenPagoHistorialItem>> fetchResumenesPago({
    required ResumenesPagoQuery query,
  }) async {
    final payload = await _httpClient.getJson(
      '/liquidaciones/resumenes-pago',
      queryParameters: <String, String>{
        if ((query.tecnicoId ?? '').trim().isNotEmpty)
          'tecnicoId': query.tecnicoId!.trim(),
        if ((query.desde ?? '').trim().isNotEmpty) 'desde': query.desde!.trim(),
        if ((query.hasta ?? '').trim().isNotEmpty) 'hasta': query.hasta!.trim(),
        'page': query.page.toString(),
        'limit': query.limit.toString(),
      },
    );

    return PagedResult<ResumenPagoHistorialItem>.fromDynamic(
      payload,
      (json) {
        final root = _asMap(json);
        return ResumenPagoHistorialItem(
          id: _stringOrNull(root['id']) ?? '-',
          tecnicoId: _stringOrNull(root['tecnicoId'] ?? root['tecnico_id']) ?? '-',
          tecnicoNombre:
              _stringOrNull(root['tecnicoNombre'] ?? root['tecnico_nombre']) ?? '-',
          desde: _stringOrNull(root['desde']) ?? '-',
          hasta: _stringOrNull(root['hasta']) ?? '-',
          totalLiquidaciones:
              _toInt(root['totalLiquidaciones'] ?? root['total_liquidaciones']) ?? 0,
          totalUsdSnapshot:
              _toDouble(root['totalUsdSnapshot'] ?? root['total_usd_snapshot']),
          createdAt: _stringOrNull(root['createdAt'] ?? root['created_at']) ?? '-',
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );
  }

  @override
  Future<PagedResult<TecnicoListadoItem>> fetchTecnicosListado({
    required TecnicosListadoQuery query,
  }) async {
    final payload = await _httpClient.getJson(
      '/auth/tecnicos',
      queryParameters: <String, String>{
        'page': query.page.toString(),
        'limit': query.limit.toString(),
        'activos': query.activos ? 'true' : 'false',
        if ((query.q ?? '').trim().isNotEmpty) 'q': query.q!.trim(),
      },
    );

    return PagedResult<TecnicoListadoItem>.fromDynamic(
      payload,
      (json) {
        final root = _asMap(json);
        return TecnicoListadoItem(
          id: _stringOrNull(root['id']) ?? '-',
          fullName: _stringOrNull(root['fullName'] ?? root['full_name']) ?? '-',
          email: _stringOrNull(root['email']) ?? '-',
          isActive: _toBool(root['isActive'] ?? root['is_active'] ?? true),
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );
  }

  @override
  Future<UltimoResumenPagoItem?> fetchUltimoResumenPago(String tecnicoId) async {
    final payload = await _httpClient.getJson(
      '/liquidaciones/resumenes-pago/ultimo',
      queryParameters: <String, String>{
        'tecnicoId': tecnicoId.trim(),
      },
    );

    final root = _asMap(payload);
    final ultimo = _asMap(root['ultimoResumen']);
    if (ultimo.isEmpty) {
      return null;
    }

    return UltimoResumenPagoItem(
      id: _stringOrNull(ultimo['id']) ?? '-',
      desde: _stringOrNull(ultimo['desde']) ?? '-',
      hasta: _stringOrNull(ultimo['hasta']) ?? '-',
      totalLiquidaciones: _toInt(ultimo['totalLiquidaciones']) ?? 0,
      totalUsdSnapshot: _toDouble(ultimo['totalUsdSnapshot']),
      createdAt: _stringOrNull(ultimo['createdAt']) ?? '-',
    );
  }

  @override
  Future<ResumenPagoDetalleResponse> fetchResumenPagoDetalle(String resumenId) async {
    final payload = await _httpClient.getJson(
      '/liquidaciones/resumenes-pago/${resumenId.trim()}',
    );

    final root = _asMap(payload);
    final tecnico = _asMap(root['tecnico']);
    final periodo = _asMap(root['periodo']);
    final resumen = _asMap(root['resumen']);
    final createdBy = _asMap(root['createdBy']);
    final detallesRaw = root['detalles'];
    final detallesList = detallesRaw is List ? detallesRaw : const <dynamic>[];

    final detalles = detallesList.map(_asMap).map((detail) {
      final servicioNode = _asMap(detail['servicio']);
      final clienteNode = _asMap(detail['cliente'] ?? servicioNode['cliente']);

      return ResumenPagoDetalleItem(
        id: _stringOrNull(detail['id']) ?? '-',
        liquidacionId:
            _stringOrNull(detail['liquidacionId'] ?? detail['liquidacion_id']) ?? '-',
        servicioId:
            _stringOrNull(detail['servicioId'] ?? detail['servicio_id']) ?? '-',
        fechaAprobacionSnapshot: _stringOrNull(
          detail['fechaAprobacionSnapshot'] ?? detail['fecha_aprobacion_snapshot'],
        ),
        subtotalSalidaUsdSnapshot: _toDouble(
          detail['subtotalSalidaUsdSnapshot'] ?? detail['subtotal_salida_usd_snapshot'],
        ),
        subtotalItemsUsdSnapshot: _toDouble(
          detail['subtotalItemsUsdSnapshot'] ?? detail['subtotal_items_usd_snapshot'],
        ),
        totalLiquidacionUsdSnapshot: _toDouble(
          detail['totalLiquidacionUsdSnapshot'] ??
              detail['total_liquidacion_usd_snapshot'],
        ),
        clienteNombre: _stringOrNull(
          detail['clienteNombre'] ??
              detail['cliente_nombre'] ??
              servicioNode['clienteNombre'] ??
              servicioNode['cliente_nombre'] ??
              clienteNode['nombre'] ??
              clienteNode['razonSocial'] ??
              clienteNode['razon_social'],
        ),
        fechaHoraServicio: _stringOrNull(
          detail['fechaHoraServicio'] ??
              detail['fecha_hora_servicio'] ??
              servicioNode['fechaHoraServicio'] ??
              servicioNode['fecha_hora_servicio'],
        ),
      );
    }).toList();

    final tecnicoIdDetalle = _stringOrNull(tecnico['id']) ?? '';
    final lookupDetalle = enableClienteHydration
        ? await _fetchLiquidacionResumenPorTecnico(
            tecnicoIdDetalle,
            liquidadaPago: true,
          )
        : const <String, _LiquidacionResumen>{};

    final detallesConLookup = detalles.map((item) {
      final resumen = lookupDetalle[item.liquidacionId];
      if (resumen == null) {
        return item;
      }
      return item.copyWith(
        clienteNombre: resumen.clienteNombre,
        tipoSalidaNombre: resumen.tipoSalidaNombre,
      );
    }).toList();

    final detallesHidratados = !enableClienteHydration
        ? detallesConLookup
        : await _hydrateFromServicios<ResumenPagoDetalleItem>(
            items: detallesConLookup,
            needsHydration: (item) => (item.clienteNombre ?? '').trim().isEmpty,
            hydrate: (item) async {
              final servicio = await _fetchServicioResumen(item.servicioId);
              if (servicio == null) {
                return item;
              }
              return item.copyWith(
                clienteNombre: servicio.clienteNombre,
                fechaHoraServicio: servicio.fechaHoraServicio,
              );
            },
          );

    return ResumenPagoDetalleResponse(
      id: _stringOrNull(root['id']) ?? '-',
      tecnicoId: _stringOrNull(tecnico['id']) ?? '-',
      tecnicoNombre: _stringOrNull(tecnico['nombre']) ?? '-',
      tecnicoEmail: _stringOrNull(tecnico['email']) ?? '-',
      desde: _stringOrNull(periodo['desde']) ?? '-',
      hasta: _stringOrNull(periodo['hasta']) ?? '-',
      totalLiquidaciones: _toInt(resumen['totalLiquidaciones']) ?? 0,
      totalUsdSnapshot: _toDouble(resumen['totalUsdSnapshot']),
      createdByNombre: _stringOrNull(createdBy['nombre']) ?? '-',
      createdAt: _stringOrNull(root['createdAt']) ?? '-',
      detalles: detallesHidratados,
    );
  }

  /// Datos que el flujo de resumen de pago no devuelve pero GET /liquidaciones
  /// si: sobre todo el nombre del tipo de salida, que es lo que el admin usa
  /// para reconocer la salida al aprobar.
  ///
  /// Se consulta el universo elegible del tecnico (aprobadas y no liquidadas),
  /// superconjunto de cualquier periodo del preview, y se cachea por tecnico
  /// mientras viva el repositorio.
  Future<Map<String, _LiquidacionResumen>> _fetchLiquidacionResumenPorTecnico(
    String tecnicoId, {
    required bool liquidadaPago,
  }) async {
    final id = tecnicoId.trim();
    if (id.isEmpty) {
      return const <String, _LiquidacionResumen>{};
    }

    // El preview mira liquidaciones sin pagar y el detalle confirmado mira las
    // ya pagadas: son universos disjuntos, por eso el flag entra en la clave.
    final cacheKey = '$id|$liquidadaPago';
    final cached = _liquidacionResumenPorTecnico[cacheKey];
    if (cached != null) {
      return cached;
    }

    final resumen = <String, _LiquidacionResumen>{};
    try {
      var page = 1;
      while (page <= _maxLiquidacionLookupPages) {
        final result = await fetchLiquidaciones(
          query: LiquidacionesQuery(
            tecnicoId: id,
            aprobado: true,
            liquidadaPago: liquidadaPago,
            page: page,
            limit: _liquidacionLookupPageSize,
          ),
        );

        for (final item in result.items) {
          resumen[item.id] = _LiquidacionResumen(
            clienteNombre: item.clienteNombre,
            tipoSalidaNombre: item.tipoSalidaNombre,
          );
        }

        final vistos = page * _liquidacionLookupPageSize;
        if (result.items.isEmpty || vistos >= result.total) {
          break;
        }
        page += 1;
      }
    } catch (_) {
      // Best-effort: sin el lookup el resumen se sigue pudiendo aprobar por
      // montos, solo pierde el nombre de la salida.
    }

    _liquidacionResumenPorTecnico[cacheKey] = resumen;
    return resumen;
  }

  /// Completa cada fila del resumen con los datos del servicio (cliente, fecha)
  /// que el endpoint de resumen-pago no devuelve. El mapper sigue siendo
  /// sincronico porque lo comparten preview y confirmar.
  Future<ResumenPagoPreviewResponse> _mapAndHydrateResumenPagoPreview(
    dynamic payload, {
    required String tecnicoId,
  }) async {
    final mapped = _mapResumenPagoPreviewResponse(payload);
    if (!enableClienteHydration) {
      return mapped;
    }

    // Primero el lookup por tecnico: una consulta paginada resuelve el tipo de
    // salida y, de paso, el cliente de casi todas las filas.
    final lookup = await _fetchLiquidacionResumenPorTecnico(
      tecnicoId,
      liquidadaPago: false,
    );
    final desdeLookup = mapped.items.map((item) {
      final resumen = lookup[item.id];
      if (resumen == null) {
        return item;
      }
      return item.copyWith(
        clienteNombre: resumen.clienteNombre,
        tipoSalidaNombre: resumen.tipoSalidaNombre,
      );
    }).toList();

    // Y recien despues, un GET /servicios/:id por cada fila que quedo sin
    // cliente.
    final hydrated = await _hydrateFromServicios<ResumenPagoPreviewItem>(
      items: desdeLookup,
      needsHydration: (item) => (item.clienteNombre ?? '').trim().isEmpty,
      hydrate: (item) async {
        final servicio = await _fetchServicioResumen(item.servicioId);
        if (servicio == null) {
          return item;
        }
        return item.copyWith(
          clienteNombre: servicio.clienteNombre,
          fechaHoraServicio: servicio.fechaHoraServicio,
        );
      },
    );

    return ResumenPagoPreviewResponse(
      items: hydrated,
      meta: mapped.meta,
      confirmacion: mapped.confirmacion,
    );
  }

  ResumenPagoPreviewResponse _mapResumenPagoPreviewResponse(dynamic payload) {
    final root = _asMap(payload);
    final rowsRaw = root['data'];
    final rows = rowsRaw is List ? rowsRaw : const <dynamic>[];
    final meta = _asMap(root['meta']);
    final confirmacion = _asMap(root['confirmacion']);

    return ResumenPagoPreviewResponse(
      items: rows.map(_asMap).map((row) {
        final servicioNode = _asMap(row['servicio']);
        final clienteNode = _asMap(row['cliente'] ?? servicioNode['cliente']);

        return ResumenPagoPreviewItem(
          id: _stringOrNull(row['id']) ?? '-',
          servicioId: _stringOrNull(row['servicioId'] ?? row['servicio_id']) ?? '-',
          fechaAprobacion:
              _stringOrNull(row['fechaAprobacion'] ?? row['fecha_aprobacion']),
          subtotalSalidaUsd:
              _toDouble(row['subtotalSalidaUsd'] ?? row['subtotal_salida_usd']),
          subtotalItemsUsd:
              _toDouble(row['subtotalItemsUsd'] ?? row['subtotal_items_usd']),
          totalLiquidacionUsd:
              _toDouble(row['totalLiquidacionUsd'] ?? row['total_liquidacion_usd']),
          // Hoy el backend no lo manda, pero si algun dia lo hace evitamos el
          // fan-out de hidratacion por completo.
          clienteNombre: _stringOrNull(
            row['clienteNombre'] ??
                row['cliente_nombre'] ??
                servicioNode['clienteNombre'] ??
                servicioNode['cliente_nombre'] ??
                clienteNode['nombre'] ??
                clienteNode['razonSocial'] ??
                clienteNode['razon_social'],
          ),
          fechaHoraServicio: _stringOrNull(
            row['fechaHoraServicio'] ??
                row['fecha_hora_servicio'] ??
                servicioNode['fechaHoraServicio'] ??
                servicioNode['fecha_hora_servicio'],
          ),
        );
      }).toList(),
      meta: ResumenPagoPreviewMeta(
        totalLiquidaciones:
            _toInt(meta['totalLiquidaciones'] ?? meta['total_liquidaciones']) ?? 0,
        totalResumenUsd:
            _toDouble(meta['totalResumenUsd'] ?? meta['total_resumen_usd']),
      ),
      confirmacion: confirmacion.isEmpty
          ? null
          : ResumenPagoConfirmacion(
              updated: _toInt(confirmacion['updated']) ?? 0,
              resumenPagoId: _stringOrNull(
                confirmacion['resumenPagoId'] ??
                    confirmacion['resumen_pago_id'] ??
                    root['resumenPagoId'] ??
                    root['resumen_pago_id'],
              ),
              fechaLiquidadaPago: _stringOrNull(confirmacion['fechaLiquidadaPago']),
            ),
    );
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
    final estado = _stringOrNull(query.estado);
    final liquidadaPago = query.liquidadaPago;
    final liquidadaPagoValue =
        liquidadaPago == null ? null : (liquidadaPago ? 'true' : 'false');
    final tecnicoKeys = tecnicoId == null
        ? const <String?>[null]
        : const <String?>['tecnicoId', 'tecnico_id'];
    final aprobadoKeys = aprobadoValue == null
        ? const <String?>[null]
        : const <String?>['aprobado'];
    final estadoKeys = estado == null
        ? const <String?>[null]
        : const <String?>['estado'];

    final signatures = <String>{};
    final candidates = <Map<String, String>>[];

    void addCandidate({
      required bool includePagination,
      required String? tecnicoKey,
      required String? aprobadoKey,
      required String? estadoKey,
    }) {
      final params = <String, String>{
        if (tecnicoKey != null && tecnicoId != null) tecnicoKey: tecnicoId,
        if (aprobadoKey != null && aprobadoValue != null) aprobadoKey: aprobadoValue,
        if (estadoKey != null && estado != null) estadoKey: estado,
        'liquidadaPago': ?liquidadaPagoValue,
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
        for (final estadoKey in estadoKeys) {
          addCandidate(
            includePagination: true,
            tecnicoKey: tecnicoKey,
            aprobadoKey: aprobadoKey,
            estadoKey: estadoKey,
          );
          addCandidate(
            includePagination: false,
            tecnicoKey: tecnicoKey,
            aprobadoKey: aprobadoKey,
            estadoKey: estadoKey,
          );
        }
      }
    }

    return candidates;
  }

  List<Map<String, String>> _buildPendientesQueryCandidates(
    LiquidacionesPendientesQuery query,
  ) {
    final tecnicoId = _stringOrNull(query.tecnicoId);
    final estado = _stringOrNull(query.estado);
    final tecnicoKeys = tecnicoId == null
        ? const <String?>[null]
        : const <String?>['tecnicoId', 'tecnico_id'];
    final estadoKeys = estado == null
        ? const <String?>[null]
        : const <String?>['estado'];

    final signatures = <String>{};
    final candidates = <Map<String, String>>[];

    void addCandidate({
      required bool includePagination,
      required String? tecnicoKey,
      required String? estadoKey,
    }) {
      final params = <String, String>{
        if (tecnicoKey != null && tecnicoId != null) tecnicoKey: tecnicoId,
        if (estadoKey != null && estado != null) estadoKey: estado,
        if (includePagination) 'page': query.page.toString(),
        if (includePagination) 'limit': query.limit.toString(),
      };

      final signature = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
      if (signatures.add(signature)) {
        candidates.add(params);
      }
    }

    for (final tecnicoKey in tecnicoKeys) {
      for (final estadoKey in estadoKeys) {
        addCandidate(
          includePagination: true,
          tecnicoKey: tecnicoKey,
          estadoKey: estadoKey,
        );
        addCandidate(
          includePagination: false,
          tecnicoKey: tecnicoKey,
          estadoKey: estadoKey,
        );
      }
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
      'serviciosPendientes',
      'servicios_pendientes',
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
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final direct = int.tryParse(trimmed);
      if (direct != null) {
        return direct;
      }

      final normalized = trimmed.replaceAll(',', '.');
      final parsedDecimal = double.tryParse(normalized);
      return parsedDecimal?.toInt();
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

  String? _resolveClienteNombrePendiente({
    required Map<String, dynamic> root,
    required Map<String, dynamic> source,
    required Map<String, dynamic> clienteNode,
    String? clienteTextoPlano,
  }) {
    final direct = _stringOrNull(
      root['clienteNombre'] ??
          root['cliente_nombre'] ??
          root['razonSocial'] ??
          root['razon_social'] ??
          root['clienteRazonSocial'] ??
          root['cliente_razon_social'] ??
          source['clienteNombre'] ??
          source['cliente_nombre'] ??
          source['razonSocial'] ??
          source['razon_social'] ??
          source['clienteRazonSocial'] ??
          source['cliente_razon_social'] ??
          clienteNode['nombre'] ??
          clienteNode['razonSocial'] ??
          clienteNode['razon_social'] ??
          clienteNode['nombreFantasia'] ??
          clienteNode['nombre_fantasia'] ??
          clienteTextoPlano,
    );

    if (direct != null && !_looksLikeUuid(direct)) {
      return direct;
    }

    return _searchClienteNombre(
      root,
      clienteContext: false,
      depth: 0,
    );
  }

  String? _searchClienteNombre(
    dynamic node, {
    required bool clienteContext,
    required int depth,
  }) {
    if (depth > 8) {
      return null;
    }

    if (node is List) {
      for (final entry in node) {
        final found = _searchClienteNombre(
          entry,
          clienteContext: clienteContext,
          depth: depth + 1,
        );
        if (found != null) {
          return found;
        }
      }
      return null;
    }

    if (node is Map) {
      final map = _asMap(node);

      final direct = _stringOrNull(
        map['clienteNombre'] ??
            map['cliente_nombre'] ??
            map['clienteRazonSocial'] ??
            map['cliente_razon_social'],
      );
      if (direct != null && !_looksLikeUuid(direct)) {
        return direct;
      }

      if (clienteContext) {
        final nameFromClienteMap = _stringOrNull(
          map['nombre'] ??
              map['razonSocial'] ??
              map['razon_social'] ??
              map['nombreFantasia'] ??
              map['nombre_fantasia'],
        );
        if (nameFromClienteMap != null && !_looksLikeUuid(nameFromClienteMap)) {
          return nameFromClienteMap;
        }
      }

      for (final entry in map.entries) {
        final nextClienteContext =
            clienteContext || entry.key.toLowerCase().contains('cliente');
        final found = _searchClienteNombre(
          entry.value,
          clienteContext: nextClienteContext,
          depth: depth + 1,
        );
        if (found != null) {
          return found;
        }
      }

      return null;
    }

    if (node is String && clienteContext) {
      final text = _stringOrNull(node);
      if (text != null && !_looksLikeUuid(text)) {
        return text;
      }
    }

    return null;
  }

  bool _looksLikeUuid(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return false;
    }

    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[1-5][0-9a-fA-F]{3}\-[89abAB][0-9a-fA-F]{3}\-[0-9a-fA-F]{12}$',
    );
    return uuidPattern.hasMatch(text);
  }
}

/// Datos del servicio que el flujo de liquidaciones necesita pero que los
/// endpoints de liquidacion/resumen no devuelven. Se resuelven con
/// GET /servicios/:id y se cachean por servicioId.
class _ServicioResumen {
  const _ServicioResumen({
    this.clienteNombre,
    this.canal,
    this.fechaHoraServicio,
    this.kmSugerido,
  });

  final String? clienteNombre;
  final String? canal;
  final String? fechaHoraServicio;
  final int? kmSugerido;
}

/// Datos de una liquidacion que solo estan en GET /liquidaciones.
class _LiquidacionResumen {
  const _LiquidacionResumen({this.clienteNombre, this.tipoSalidaNombre});

  final String? clienteNombre;
  final String? tipoSalidaNombre;
}
