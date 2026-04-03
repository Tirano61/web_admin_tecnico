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
    final requested = normalizedTipo == 'todos' || normalizedTipo.isEmpty
        ? <String>['zona', 'categoria', 'producto', 'repuesto']
        : <String>[normalizedTipo];

    final results = await Future.wait<List<CatalogoItem>>(
      requested.map((tipo) => _fetchByTipo(tipo, query)),
    );

    final merged = <CatalogoItem>[for (final list in results) ...list];
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
    );

    await _sendWithFallback(
      candidates,
      (body) => _httpClient.patchJson(endpoint, body: body),
    );
  }

  Future<List<CatalogoItem>> _fetchByTipo(String tipo, CatalogosQuery query) async {
    switch (tipo) {
      case 'zona':
        return _fetchSimple('/zonas', 'zona', query);
      case 'categoria':
        return _fetchSimple('/categorias-producto', 'categoria', query);
      case 'producto':
        return _fetchSimple('/productos', 'producto', query);
      case 'repuesto':
      default:
        return _fetchSimple('/repuestos', 'repuesto', query);
    }
  }

  Future<List<CatalogoItem>> _fetchSimple(
    String endpoint,
    String tipo,
    CatalogosQuery query,
  ) async {
    dynamic payload;
    final supportsSearch = endpoint == '/repuestos';
    try {
      payload = await _httpClient.getJson(
        endpoint,
        queryParameters: <String, String>{
          if (supportsSearch) 'q': query.search,
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      );
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }
      payload = await _httpClient.getJson(
        endpoint,
        queryParameters: <String, String>{
          if (supportsSearch) 'q': query.search,
        },
      );
    }

    final paged = PagedResult<CatalogoItem>.fromDynamic(
      payload,
      (json) {
        final id = (json['id'] ?? '').toString();
        final nombre =
            (json['nombre'] ?? json['descripcion'] ?? json['detalle'] ?? json['codigo'] ?? '').toString();
        final activoRaw = json['activo'];
        return CatalogoItem(
          id: id,
          nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
          tipo: tipo,
          activo: activoRaw is bool ? activoRaw : true,
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    return paged.items;
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
  }) {
    final cleanNombre = nombre.trim();
    final cleanCategoriaId = categoriaId?.trim() ?? '';
    final normalizedTipo = tipo.toLowerCase();
    final withCategoria = normalizedTipo == 'producto' && cleanCategoriaId.isNotEmpty;

    final candidates = <Map<String, dynamic>>[];
    final signatures = <String>{};

    void addCandidate(
      String labelKey, {
      String? categoriaKey,
      bool withActivo = false,
    }) {
      final body = <String, dynamic>{
        labelKey: cleanNombre,
      };
      if (withCategoria && categoriaKey != null) {
        body[categoriaKey] = cleanCategoriaId;
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
}
