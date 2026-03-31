import 'package:web_admin_tecnico/core/api/paged_result.dart';

class CatalogoItem {
  const CatalogoItem({required this.id, required this.nombre, required this.tipo});

  final String id;
  final String nombre;
  final String tipo;
}

class CatalogosQuery {
  const CatalogosQuery({
    this.search = '',
    this.tipo = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String tipo;
  final int page;
  final int limit;

  CatalogosQuery copyWith({String? search, String? tipo, int? page, int? limit}) {
    return CatalogosQuery(
      search: search ?? this.search,
      tipo: tipo ?? this.tipo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

abstract class CatalogosRepository {
  Future<PagedResult<CatalogoItem>> fetchCatalogos({required CatalogosQuery query});
}
