import 'dart:convert';

import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';

class CatalogosRepositoryImpl implements CatalogosRepository {
  CatalogosRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<CatalogoItem>> fetchCatalogos({required CatalogosQuery query}) async {
    final normalizedTipo = query.tipo.toLowerCase();

    if (normalizedTipo != 'todos' && normalizedTipo.isNotEmpty) {
      return _fetchByTipo(normalizedTipo, query);
    }

    final requested = normalizedTipo == 'todos' || normalizedTipo.isEmpty
      ? <String>['zona', 'categoria', 'producto']
        : <String>[normalizedTipo];

    final results = await Future.wait<PagedResult<CatalogoItem>>(
      requested.map((tipo) => _fetchByTipo(tipo, query, usePagination: false)),
    );

    final merged = <CatalogoItem>[for (final result in results) ...result.items];
    final search = query.search.trim().toLowerCase();
    final filtered = merged.where((item) {
      final matchText = search.isEmpty
          ? true
          : item.id.toLowerCase().contains(search) || item.nombre.toLowerCase().contains(search);
      final matchTipo = normalizedTipo == 'todos' || normalizedTipo.isEmpty
          ? true
          : item.tipo.toLowerCase() == normalizedTipo;
      return matchText && matchTipo;
    }).toList();

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pageItems = start >= filtered.length
        ? <CatalogoItem>[]
        : filtered.sublist(start, end > filtered.length ? filtered.length : end);

    return PagedResult<CatalogoItem>(
      items: pageItems,
      total: filtered.length,
      page: query.page,
      limit: query.limit,
    );
  }

  @override
  Future<void> createCatalogo({required CreateCatalogoInput input}) async {
    final endpoint = _endpointByTipo(input.tipo);
    final candidates = _buildBodyCandidates(
      tipo: input.tipo,
      nombre: input.nombre,
      categoriaId: input.categoriaId,
      activo: input.activo,
      codigo: input.codigo,
      precioUsd: input.precioUsd,
    );

    await _sendWithFallback(
      candidates,
      (body) => _httpClient.postJson(endpoint, body: body),
    );
  }

  @override
  Future<void> updateCatalogo({required UpdateCatalogoInput input}) async {
    final endpoint = '${_endpointByTipo(input.tipo)}/${input.id}';
    final candidates = _buildBodyCandidates(
      tipo: input.tipo,
      nombre: input.nombre,
      categoriaId: input.categoriaId,
      activo: input.activo,
      codigo: input.codigo,
      precioUsd: input.precioUsd,
    );

    await _sendWithFallback(
      candidates,
      (body) => _httpClient.patchJson(endpoint, body: body),
    );
  }

  Future<PagedResult<CatalogoItem>> _fetchByTipo(
    String tipo,
    CatalogosQuery query, {
    bool usePagination = true,
  }) async {
    switch (tipo) {
      case 'zona':
        return _fetchSimple('/zonas', 'zona', query, usePagination: usePagination);
      case 'categoria':
        return _fetchSimple('/categorias-producto', 'categoria', query, usePagination: usePagination);
      case 'producto':
        return _fetchSimple('/productos', 'producto', query, usePagination: usePagination);
      case 'repuesto':
      default:
        return _fetchSimple('/repuestos/listado', 'repuesto', query, usePagination: usePagination);
    }
  }

  Future<PagedResult<CatalogoItem>> _fetchSimple(
    String endpoint,
    String tipo,
    CatalogosQuery query, {
    bool usePagination = true,
  }
  ) async {
    dynamic payload;
    final isQuickSearchEndpoint = endpoint == '/repuestos';
    final isAdminRepuestosEndpoint = endpoint == '/repuestos/listado';
    final supportsServerPagination = endpoint != '/productos';
    final supportsSearch = isQuickSearchEndpoint || isAdminRepuestosEndpoint;
    final supportsActivoFilter = isAdminRepuestosEndpoint;
    final trimmedSearch = query.search.trim();
    final includeSearchParam = supportsSearch && (trimmedSearch.isNotEmpty || isQuickSearchEndpoint);
    final keepEmptyParams = isQuickSearchEndpoint;

    Map<String, String> buildQueryParameters({required bool includeSearch}) {
      return <String, String>{
        if (includeSearchParam && includeSearch) 'q': trimmedSearch,
        if (supportsActivoFilter && query.activo != null) 'activo': query.activo!.toString(),
        if (usePagination && supportsServerPagination) 'page': query.page.toString(),
        if (usePagination && supportsServerPagination) 'limit': query.limit.toString(),
      };
    }

    try {
      payload = await _httpClient.getJson(
        endpoint,
        queryParameters: buildQueryParameters(includeSearch: true),
        keepEmptyQueryParameters: keepEmptyParams,
      );
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }

      // Retry sin parametro de busqueda para endpoints que validan q cuando llega vacio.
      payload = await _httpClient.getJson(
        endpoint,
        queryParameters: buildQueryParameters(includeSearch: trimmedSearch.isNotEmpty),
        keepEmptyQueryParameters: keepEmptyParams,
      );
    }

    final paged = PagedResult<CatalogoItem>.fromDynamic(
      payload,
      (json) {
        final id = (json['id'] ?? '').toString();
        final nombre =
            (json['nombre'] ?? json['descripcion'] ?? json['detalle'] ?? json['codigo'] ?? '').toString();
        final codigo = (json['codigo'] ?? json['codigoRepuesto'] ?? '').toString().trim();
        final precioUsd = _toDouble(json['precioUsd'] ?? json['precio_usd'] ?? json['precio']);
        final activoRaw = json['activo'];
        return CatalogoItem(
          id: id,
          nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
          tipo: tipo,
          activo: activoRaw is bool ? activoRaw : true,
          codigo: codigo.isEmpty ? null : codigo,
          precioUsd: precioUsd,
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    if (usePagination && !supportsServerPagination) {
      final start = (query.page - 1) * query.limit;
      final end = start + query.limit;
      final pageItems = start >= paged.items.length
          ? <CatalogoItem>[]
          : paged.items.sublist(start, end > paged.items.length ? paged.items.length : end);

      return PagedResult<CatalogoItem>(
        items: pageItems,
        total: paged.items.length,
        page: query.page,
        limit: query.limit,
      );
    }

    return paged;
  }

  String _endpointByTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'zona':
        return '/zonas';
      case 'categoria':
        return '/categorias-producto';
      case 'producto':
        return '/productos';
      case 'repuesto':
        return '/repuestos';
      default:
        throw const AppFailure('Tipo de catalogo no soportado');
    }
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

    throw lastFailure ?? const AppFailure('No se pudo procesar el catalogo');
  }

  List<Map<String, dynamic>> _buildBodyCandidates({
    required String tipo,
    required String nombre,
    String? categoriaId,
    bool? activo,
    String? codigo,
    double? precioUsd,
  }) {
    final cleanNombre = nombre.trim();
    final cleanCategoriaId = categoriaId?.trim() ?? '';
    final cleanCodigo = codigo?.trim() ?? '';
    final normalizedTipo = tipo.toLowerCase();
    final withCategoria = normalizedTipo == 'producto' && cleanCategoriaId.isNotEmpty;
    final isRepuesto = normalizedTipo == 'repuesto';
    final withCodigo = isRepuesto && cleanCodigo.isNotEmpty;
    final withPrecio = isRepuesto && precioUsd != null;

    final candidates = <Map<String, dynamic>>[];
    final signatures = <String>{};

    void addCandidate(
      String labelKey, {
      String? categoriaKey,
      String? codigoKey,
      String? precioKey,
      bool withActivo = false,
    }) {
      final body = <String, dynamic>{
        labelKey: cleanNombre,
      };
      if (withCategoria && categoriaKey != null) {
        body[categoriaKey] = cleanCategoriaId;
      }
      if (withCodigo && codigoKey != null) {
        body[codigoKey] = cleanCodigo;
      }
      if (withPrecio && precioKey != null) {
        body[precioKey] = precioUsd;
      }
      if (withActivo && activo != null) {
        body['activo'] = activo;
      }

      final signature = jsonEncode(body);
      if (!signatures.contains(signature)) {
        signatures.add(signature);
        candidates.add(body);
      }
    }

    if (isRepuesto) {
      const labels = <String>['nombre', 'descripcion'];
      const precios = <String>['precioUsd', 'precio_usd', 'precio'];

      for (final label in labels) {
        for (final precioKey in precios) {
          addCandidate(label, codigoKey: 'codigo', precioKey: precioKey, withActivo: false);
        }
      }
      for (final label in labels) {
        for (final precioKey in precios) {
          addCandidate(label, codigoKey: 'codigo', precioKey: precioKey, withActivo: true);
        }
      }
    }

    if (withCategoria) {
      const categoriaKeys = <String>['categoriaId', 'categoria_id', 'categoriaProductoId'];
      for (final categoriaKey in categoriaKeys) {
        addCandidate('nombre', categoriaKey: categoriaKey, withActivo: false);
      }
      for (final categoriaKey in categoriaKeys) {
        addCandidate('nombre', categoriaKey: categoriaKey, withActivo: true);
      }
      for (final categoriaKey in categoriaKeys) {
        addCandidate('descripcion', categoriaKey: categoriaKey, withActivo: false);
      }
      for (final categoriaKey in categoriaKeys) {
        addCandidate('descripcion', categoriaKey: categoriaKey, withActivo: true);
      }
    }

    addCandidate('nombre', withActivo: false);
    addCandidate('nombre', withActivo: true);
    addCandidate('descripcion', withActivo: false);
    addCandidate('descripcion', withActivo: true);
    addCandidate('detalle', withActivo: false);
    addCandidate('detalle', withActivo: true);

    return candidates;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}
