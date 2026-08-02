import 'dart:convert';
import 'dart:developer' as developer;

import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

class ServiciosRepositoryImpl implements ServiciosRepository {
  ServiciosRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<ServicioItem>> fetchServicios({required ServiciosQuery query}) async {
    final payload = await _fetchServiciosPayload(query: query);
    developer.log(
      '>>> GET /servicios response:\n${const JsonEncoder.withIndent('  ').convert(payload)}',
      name: 'ServiciosRepository',
    );

    final result = PagedResult<ServicioItem>.fromDynamic(
      payload,
      (json) {
        final servicioNode = _asMap(json['servicio']);
        return ServicioItem(
          id: _resolveId(json, servicioNode),
          descripcion: _resolveDescripcion(json, servicioNode),
          estadoOrden: _resolveEstadoOrden(json, servicioNode),
          canal: _resolveCanal(json, servicioNode),
          fechaHoraServicio: _resolveFechaHoraServicio(json, servicioNode),
          equipoSerie: _resolveEquipoSerie(json, servicioNode),
          equipoModelo: _resolveEquipoModelo(json, servicioNode),
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    final sortedItems = List<ServicioItem>.from(result.items)
      ..sort(_compareServiciosByFechaDesc);

    if (sortedItems.length <= query.limit) {
      return PagedResult<ServicioItem>(
        items: sortedItems,
        total: result.total,
        page: result.page,
        limit: result.limit,
      );
    }

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pagedItems = start >= sortedItems.length
        ? <ServicioItem>[]
        : sortedItems.sublist(start, end > sortedItems.length ? sortedItems.length : end);

    return PagedResult<ServicioItem>(
      items: pagedItems,
      total: result.total,
      page: query.page,
      limit: query.limit,
    );
  }

  @override
  Future<List<ServicioTecnicoOption>> fetchTecnicosFiltro() async {
    final payload = await _httpClient.getJson(
      '/auth/tecnicos',
      queryParameters: const <String, String>{
        'page': '1',
        'limit': '100',
        'activos': 'true',
      },
    );

    final result = PagedResult<ServicioTecnicoOption>.fromDynamic(
      payload,
      (json) {
        final root = _asMap(json);
        return ServicioTecnicoOption(
          id: _stringOrNull(root['id']) ?? '',
          fullName: _stringOrNull(root['fullName'] ?? root['full_name']) ?? '',
          email: _stringOrNull(root['email']) ?? '',
          isActive: _toBool(root['isActive'] ?? root['is_active'] ?? true),
        );
      },
      fallbackPage: 1,
      fallbackLimit: 100,
    );

    final byId = <String, ServicioTecnicoOption>{};
    for (final tecnico in result.items) {
      final id = tecnico.id.trim();
      if (id.isEmpty) {
        continue;
      }

      final existing = byId[id];
      if (existing == null) {
        byId[id] = tecnico;
        continue;
      }

      final resolvedName = existing.fullName.trim().isEmpty ? tecnico.fullName : existing.fullName;
      final resolvedEmail = existing.email.trim().isEmpty ? tecnico.email : existing.email;
      byId[id] = ServicioTecnicoOption(
        id: id,
        fullName: resolvedName,
        email: resolvedEmail,
        isActive: existing.isActive || tecnico.isActive,
      );
    }

    final output = byId.values.where((item) => item.isActive).toList();
    output.sort((a, b) {
      final left = _tecnicoLabel(a).toLowerCase();
      final right = _tecnicoLabel(b).toLowerCase();
      return left.compareTo(right);
    });
    return output;
  }

  Future<dynamic> _fetchServiciosPayload({required ServiciosQuery query}) async {
    AppFailure? lastFailure;

    for (final params in _buildServiciosQueryCandidates(query)) {
      try {
        return await _httpClient.getJson(
          '/servicios',
          queryParameters: params,
        );
      } on AppFailure catch (error) {
        if (error.statusCode != 400) {
          rethrow;
        }
        lastFailure = error;
      }
    }

    throw lastFailure ?? const AppFailure('No se pudo obtener servicios');
  }

  List<Map<String, String>> _buildServiciosQueryCandidates(ServiciosQuery query) {
    final search = query.search.trim();
    final estado = query.estado.trim().toLowerCase();
    final canal = query.canal.trim().toLowerCase();
    final tecnicoId = query.tecnicoId.trim();

    final searchValue = search.isEmpty ? null : search;
    final estadoValue = (estado.isEmpty || estado == 'todos') ? null : estado;
    final canalValue = (canal.isEmpty || canal == 'todos') ? null : canal;
    final tecnicoValue = (tecnicoId.isEmpty || tecnicoId == 'todos') ? null : tecnicoId;
    final signatures = <String>{};
    final candidates = <Map<String, String>>[];
    final searchParamKeys = searchValue == null ? <String?>[null] : <String?>['q', 'search'];
    final estadoParamKeys = estadoValue == null
        ? <String?>[null]
        : <String?>['estado', 'estadoOrden', 'estado_orden'];
    final canalParamKeys = canalValue == null
        ? <String?>[null]
        : <String?>['canal', 'canalServicio', 'canal_servicio'];
    final tecnicoParamKeys = tecnicoValue == null
        ? <String?>[null]
        : <String?>['tecnicoId', 'tecnico_id'];
    final sortParamCandidates = <Map<String, String>>[
      const <String, String>{
        'sortBy': 'fechaHoraServicio',
        'sortOrder': 'desc',
      },
      const <String, String>{},
    ];

    void addCandidate({
      required bool includePagination,
      String? searchParamKey,
      String? estadoParamKey,
      String? canalParamKey,
      String? tecnicoParamKey,
      Map<String, String> sortParams = const <String, String>{},
    }) {
      final params = <String, String>{
        if (searchParamKey != null && searchValue != null) searchParamKey: searchValue,
        if (estadoParamKey != null && estadoValue != null) estadoParamKey: estadoValue,
        if (canalParamKey != null && canalValue != null) canalParamKey: canalValue,
        if (tecnicoParamKey != null && tecnicoValue != null) tecnicoParamKey: tecnicoValue,
        ...sortParams,
        if (includePagination) 'page': query.page.toString(),
        if (includePagination) 'limit': query.limit.toString(),
      };

      final signature = params.entries.map((entry) => '${entry.key}=${entry.value}').join('&');
      if (signatures.add(signature)) {
        candidates.add(params);
      }
    }

    for (final searchKey in searchParamKeys) {
      for (final estadoKey in estadoParamKeys) {
        for (final canalKey in canalParamKeys) {
          for (final tecnicoKey in tecnicoParamKeys) {
            for (final sortParams in sortParamCandidates) {
              addCandidate(
                includePagination: true,
                searchParamKey: searchKey,
                estadoParamKey: estadoKey,
                canalParamKey: canalKey,
                tecnicoParamKey: tecnicoKey,
                sortParams: sortParams,
              );
              addCandidate(
                includePagination: false,
                searchParamKey: searchKey,
                estadoParamKey: estadoKey,
                canalParamKey: canalKey,
                tecnicoParamKey: tecnicoKey,
                sortParams: sortParams,
              );
            }
          }
        }
      }
    }

    return candidates;
  }

  int _compareServiciosByFechaDesc(ServicioItem a, ServicioItem b) {
    final aDate = _parseServicioDate(a.fechaHoraServicio);
    final bDate = _parseServicioDate(b.fechaHoraServicio);

    if (aDate != null && bDate != null) {
      final dateComparison = bDate.compareTo(aDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
    } else if (aDate == null && bDate != null) {
      return 1;
    } else if (aDate != null && bDate == null) {
      return -1;
    }

    return a.id.compareTo(b.id);
  }

  DateTime? _parseServicioDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawDate.trim());
  }

  String _tecnicoLabel(ServicioTecnicoOption tecnico) {
    final name = tecnico.fullName.trim();
    final email = tecnico.email.trim();
    if (name.isNotEmpty && email.isNotEmpty) {
      return '$name <$email>';
    }
    if (name.isNotEmpty) {
      return name;
    }
    if (email.isNotEmpty) {
      return email;
    }
    return 'ID ${tecnico.id}';
  }

  @override
  Future<ServicioDetalle> fetchServicioDetalle(String servicioId) async {
    final payload = await _httpClient.getJson('/servicios/$servicioId');
    developer.log(
      '>>> GET /servicios/$servicioId response:\n${const JsonEncoder.withIndent('  ').convert(payload)}',
      name: 'ServiciosRepository',
    );
    final root = _asMap(payload);
    final servicioNode = _asMap(root['servicio']);
    final servicioData = servicioNode.isEmpty ? root : servicioNode;
    final clienteNode = _asMap(servicioData['cliente']);
    final lugarProvinciaNode = _asMap(root['lugarProvincia']);
    final facturacionNode = _asMap(root['facturacion']);
    final facturacionItemsNode = _asList(root['facturacionItems']);
    final facturacionItemsNestedNode = _asList(facturacionNode['items']);

    final resolvedId = (root['servicioId'] ?? root['id'] ?? servicioData['id'] ?? servicioId).toString();
    final canal = (servicioData['canal'] ?? root['canal'] ?? 'sin_canal').toString();
    final lugarProvincia = (servicioData['lugarProvinciaNombre'] ??
            lugarProvinciaNode['nombre'] ??
            lugarProvinciaNode['provincia'] ??
            '')
        .toString();
    final lugarDetalle = (servicioData['lugarDetalle'] ?? '').toString();
    final lugar = [lugarProvincia, lugarDetalle]
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');
    final facturacionItemsResolved =
        facturacionItemsNode.isNotEmpty ? facturacionItemsNode : facturacionItemsNestedNode;

    return ServicioDetalle(
      id: resolvedId,
      estadoOrden: _resolveEstadoOrden(root, servicioData),
      canal: canal,
      clienteNombre: _stringOrNull(
        clienteNode['nombre'] ?? servicioData['clienteNombre'] ?? root['clienteNombre'],
      ),
      lugar: _stringOrNull(lugar),
      equipoSerie: _stringOrNull(servicioData['equipoNroSerie'] ?? servicioData['equipo_nro_serie']),
      equipoModelo: _stringOrNull(servicioData['equipoModelo'] ?? servicioData['equipo_modelo']),
      equipoAnio: _toInt(servicioData['equipoAnio'] ?? servicioData['equipo_anio']),
      sintoma: _stringOrNull(servicioData['sintoma']),
      diagnosticoDetalle: _stringOrNull(servicioData['diagnosticoDetalle']),
      observaciones: _stringOrNull(servicioData['observaciones']),
      fechaHoraServicio: _stringOrNull(root['fechaHoraServicio'] ?? servicioData['fechaHoraServicio']),
      facturacion: facturacionNode.isEmpty
          ? null
          : ServicioFacturacionResumen(
              cotizacionDolarSnapshot: _toDouble(facturacionNode['cotizacionDolarSnapshot']),
              valorKmUsdSnapshot: _toDouble(facturacionNode['valorKmUsdSnapshot']),
              subtotalKmUsd: _toDouble(facturacionNode['subtotalKmUsd']),
              subtotalKmArs: _toDouble(facturacionNode['subtotalKmArs']),
              subtotalGeneralUsd: _toDouble(facturacionNode['subtotalGeneralUsd']),
              subtotalGeneralArs: _toDouble(facturacionNode['subtotalGeneralArs']),
              ivaPorcentaje: _toDouble(facturacionNode['ivaPorcentaje']),
              totalConIvaArs: _toDouble(facturacionNode['totalConIvaArs']),
              descuentoPorcentaje: _toDouble(facturacionNode['descuentoPorcentaje']),
              totalFinalArs: _toDouble(facturacionNode['totalFinalArs']),
            ),
      facturacionItems: facturacionItemsResolved
          .map((raw) {
            final item = _asMap(raw);
            return ServicioFacturacionItem(
              tipoItem: (item['tipoItem'] ?? item['tipo_item'] ?? 'item').toString(),
              descripcion: (item['descripcion'] ?? '').toString(),
              cantidad: _toDouble(item['cantidad']),
              subtotalUsd: _toDouble(item['subtotalUsd'] ?? item['subtotal_usd']),
              subtotalArs: _toDouble(item['subtotalArs'] ?? item['subtotal_ars']),
            );
          })
          .toList(),
    );
  }

  @override
  Future<ServicioDocumentoInfo> fetchDocumento(String servicioId) async {
    final payload = await _httpClient.getJson('/servicios/$servicioId/documento');
    final root = _asMap(payload);
    final documentoNode = _asMap(root['documento']);
    final rawPdfUrl = _stringOrNull(documentoNode['pdfUrl']);

    return ServicioDocumentoInfo(
      pdfHashSha256: _stringOrNull(documentoNode['pdfHashSha256']),
      pdfUrl: _normalizePdfUrl(rawPdfUrl),
      firmaClienteNombre: _stringOrNull(documentoNode['firmaClienteNombre']),
      firmaClienteDocumento: _stringOrNull(documentoNode['firmaClienteDocumento']),
      firmaFechaHora: _stringOrNull(documentoNode['firmaFechaHora']),
    );
  }

  @override
  Future<List<int>> fetchDocumentoPdfBytes(String servicioId) async {
    final bytes = await _httpClient.getBytes('/servicios/${servicioId.trim()}/documento/pdf');
    return bytes;
  }

  String _resolveId(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final value = root['id'] ?? root['servicioId'] ?? servicioNode['id'] ?? servicioNode['servicioId'];
    return (value ?? '').toString();
  }

  String _resolveDescripcion(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final json = servicioNode.isEmpty ? root : servicioNode;
    final cliente = json['cliente'];
    final clienteNombre = cliente is Map<String, dynamic> ? cliente['nombre']?.toString() : null;
    final sintoma = json['sintoma']?.toString();
    final serie = json['equipoNroSerie']?.toString() ?? json['equipo_nro_serie']?.toString();

    if (clienteNombre != null && clienteNombre.isNotEmpty) {
      return sintoma != null && sintoma.isNotEmpty
          ? '$clienteNombre - $sintoma'
          : clienteNombre;
    }
    if (sintoma != null && sintoma.isNotEmpty) {
      return sintoma;
    }
    if (serie != null && serie.isNotEmpty) {
      return 'Equipo serie $serie';
    }

    final fallbackId = _resolveId(root, servicioNode);
    return fallbackId.isEmpty ? 'Servicio sin descripcion' : 'Servicio $fallbackId';
  }

  String _resolveEstadoOrden(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    return (root['estadoOrden'] ??
            root['estado_orden'] ??
            root['estado'] ??
            servicioNode['estadoOrden'] ??
            servicioNode['estado_orden'] ??
            servicioNode['estado'] ??
            'sin_estado')
        .toString();
  }

  String? _resolveCanal(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final value = root['canal'] ??
        root['canalServicio'] ??
        root['canal_servicio'] ??
        servicioNode['canal'] ??
        servicioNode['canalServicio'] ??
        servicioNode['canal_servicio'];
    return _stringOrNull(value);
  }

  String? _resolveFechaHoraServicio(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final value = root['fechaHoraServicio'] ??
        root['fecha_hora_servicio'] ??
        root['fecha'] ??
        root['createdAt'] ??
        servicioNode['fechaHoraServicio'] ??
        servicioNode['fecha_hora_servicio'] ??
        servicioNode['fecha'] ??
        servicioNode['createdAt'];
    return _stringOrNull(value);
  }

  String? _resolveEquipoSerie(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final value = root['equipoNroSerie'] ??
        root['equipo_nro_serie'] ??
        root['numeroIndicador'] ??
        root['numero_indicador'] ??
        servicioNode['equipoNroSerie'] ??
        servicioNode['equipo_nro_serie'] ??
        servicioNode['numeroIndicador'] ??
        servicioNode['numero_indicador'];
    return _stringOrNull(value);
  }

  String? _resolveEquipoModelo(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final value = root['equipoModelo'] ??
        root['equipo_modelo'] ??
        root['modeloIndicador'] ??
        root['modelo_indicador'] ??
        servicioNode['equipoModelo'] ??
        servicioNode['equipo_modelo'] ??
        servicioNode['modeloIndicador'] ??
        servicioNode['modelo_indicador'];
    return _stringOrNull(value);
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

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return const <dynamic>[];
  }

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
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
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  String? _normalizePdfUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = rawUrl.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    final baseUri = Uri.parse(_httpClient.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    final apiPrefix = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    if (trimmed.startsWith('/api/')) {
      return '$origin$trimmed';
    }
    if (trimmed.startsWith('/')) {
      return '$origin$apiPrefix$trimmed';
    }

    return '$origin$apiPrefix/$trimmed';
  }
}
