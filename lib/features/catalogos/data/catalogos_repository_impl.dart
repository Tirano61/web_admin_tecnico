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
        return CatalogoItem(
          id: id,
          nombre: nombre.isEmpty ? 'Sin nombre' : nombre,
          tipo: tipo,
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    return paged.items;
  }
}
