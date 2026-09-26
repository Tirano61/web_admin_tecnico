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
  Future<List<CatalogoItem>> fetchCategorias({bool incluirInactivas = false}) async {
    // Sin `activo` el backend devuelve solo las activas, que es lo que necesita
    // el selector del alta de producto.
    final payload = await _httpClient.getJson(
      '/categorias-producto',
      queryParameters: <String, String>{if (incluirInactivas) 'activo': 'todos'},
    );
    final paged = PagedResult<CatalogoItem>.fromDynamic(
      payload,
      (json) => CatalogoItem(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? json['descripcion'] ?? 'Sin categoria').toString(),
        tipo: 'categoria',
        activo: json['activo'] is bool ? json['activo'] as bool : true,
      ),
      fallbackPage: 1,
      fallbackLimit: 100,
    );

    return paged.items.where((item) => item.id.trim().isNotEmpty).toList();
  }

  @override
  Future<List<ProductosPorCategoria>> fetchProductosPorCategoria({required String search}) async {
    // Categorias y productos con `activo=todos`: el panel tiene que mostrar los
    // inactivos para poder reactivarlos.
    final categorias = await fetchCategorias(incluirInactivas: true);

    final normalizedSearch = search.trim().toLowerCase();

    final grouped = await Future.wait<ProductosPorCategoria>(
      categorias
          .where((categoria) => categoria.id.trim().isNotEmpty)
          .map((categoria) async {
        final payload = await _httpClient.getJson(
          '/productos',
          queryParameters: <String, String>{'categoriaId': categoria.id, 'activo': 'todos'},
        );

        final productosPaged = PagedResult<CatalogoItem>.fromDynamic(
          payload,
          (json) {
            final nombre = (json['nombre'] ?? json['descripcion'] ?? '').toString();
            return CatalogoItem(
              id: (json['id'] ?? '').toString(),
              nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
              tipo: 'producto',
              activo: json['activo'] is bool ? json['activo'] as bool : true,
              categoriaId: categoria.id,
              categoriaNombre: categoria.nombre,
            );
          },
          fallbackPage: 1,
          fallbackLimit: 100,
        );

        final productos = normalizedSearch.isEmpty
            ? productosPaged.items
            : productosPaged.items
                .where((item) => item.nombre.toLowerCase().contains(normalizedSearch))
                .toList();

        return ProductosPorCategoria(
          categoriaId: categoria.id,
          categoriaNombre: categoria.nombre,
          categoriaActiva: categoria.activo,
          productos: productos,
        );
      }),
    );

    return grouped.where((group) => group.productos.isNotEmpty).toList();
  }

  @override
  Future<void> createCatalogo({required CreateCatalogoInput input}) async {
    await _httpClient.postJson(
      _endpointByTipo(input.tipo),
      body: _buildCatalogoBody(
        tipo: input.tipo,
        nombre: input.nombre,
        categoriaId: input.categoriaId,
        codigo: input.codigo,
        precioUsd: input.precioUsd,
        // El activo solo existe en los DTO de update; en el alta lo rechaza el backend.
        activo: null,
      ),
    );
  }

  @override
  Future<void> updateCatalogo({required UpdateCatalogoInput input}) async {
    await _httpClient.patchJson(
      '${_endpointByTipo(input.tipo)}/${input.id}',
      body: _buildCatalogoBody(
        tipo: input.tipo,
        nombre: input.nombre,
        categoriaId: input.categoriaId,
        codigo: input.codigo,
        precioUsd: input.precioUsd,
        activo: input.activo,
      ),
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
  }) async {
    // Solo /repuestos/listado pagina y busca en el backend (page, limit, q, activo);
    // sin `activo` trae activos e inactivos.
    // /zonas, /categorias-producto y /productos solo aceptan `activo`
    // (`true | false | todos`, y /productos ademas `categoriaId`); no paginan ni
    // buscan, asi que eso se hace en memoria. Ojo: ahi omitir `activo` trae solo
    // los activos, por eso sin filtro explicito se manda `todos` para que el
    // panel muestre los inactivos y se puedan reactivar.
    final filtraEnServidor = endpoint == '/repuestos/listado';
    final trimmedSearch = query.search.trim();
    final activoParam = filtraEnServidor ? query.activo?.toString() : (query.activo?.toString() ?? 'todos');

    final payload = await _httpClient.getJson(
      endpoint,
      queryParameters: <String, String>{
        if (filtraEnServidor && trimmedSearch.isNotEmpty) 'q': trimmedSearch,
        'activo': ?activoParam,
        if (filtraEnServidor && usePagination) 'page': query.page.toString(),
        if (filtraEnServidor && usePagination) 'limit': query.limit.toString(),
      },
    );

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
          categoriaId: (json['categoriaId'] ?? json['categoria_id'] ?? '').toString().trim().isEmpty
              ? null
              : (json['categoriaId'] ?? json['categoria_id']).toString().trim(),
          categoriaNombre: (json['categoriaNombre'] ?? json['categoria_nombre'] ?? '').toString().trim().isEmpty
              ? null
              : (json['categoriaNombre'] ?? json['categoria_nombre']).toString().trim(),
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    if (filtraEnServidor) {
      return paged;
    }

    final filtered = trimmedSearch.isEmpty
        ? paged.items
        : paged.items
            .where((item) => item.nombre.toLowerCase().contains(trimmedSearch.toLowerCase()))
            .toList();

    if (!usePagination) {
      return PagedResult<CatalogoItem>(
        items: filtered,
        total: filtered.length,
        page: 1,
        limit: filtered.length,
      );
    }

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

  // Shapes tomados de los DTO del backend:
  //   CreateZonaDto              { nombre, provincia? }
  //   CreateCategoriaProductoDto { nombre }
  //   CreateProductoDto          { nombre, version?, categoriaId }
  //   CreateRepuestoDto          { codigo, nombre, precioUsd }
  // Los Update* son PartialType del create mas un activo? opcional.
  Map<String, dynamic> _buildCatalogoBody({
    required String tipo,
    required String nombre,
    String? categoriaId,
    String? codigo,
    double? precioUsd,
    bool? activo,
  }) {
    final cleanNombre = nombre.trim();
    if (cleanNombre.isEmpty) {
      throw const AppFailure('El nombre es obligatorio');
    }

    final body = <String, dynamic>{'nombre': cleanNombre};

    switch (tipo.toLowerCase()) {
      case 'zona':
      case 'categoria':
        break;
      case 'producto':
        final cleanCategoriaId = categoriaId?.trim() ?? '';
        if (cleanCategoriaId.isEmpty) {
          throw const AppFailure('La categoria es obligatoria para un producto');
        }
        body['categoriaId'] = cleanCategoriaId;
      case 'repuesto':
        final cleanCodigo = codigo?.trim() ?? '';
        if (cleanCodigo.isEmpty) {
          throw const AppFailure('El codigo es obligatorio para un repuesto');
        }
        if (precioUsd == null) {
          throw const AppFailure('El precio USD es obligatorio para un repuesto');
        }
        body['codigo'] = cleanCodigo;
        body['precioUsd'] = precioUsd;
      default:
        throw const AppFailure('Tipo de catalogo no soportado');
    }

    if (activo != null) {
      body['activo'] = activo;
    }

    return body;
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
