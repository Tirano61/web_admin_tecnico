import 'package:web_admin_tecnico/core/api/paged_result.dart';

class CatalogoItem {
  const CatalogoItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.activo = true,
    this.codigo,
    this.precioUsd,
    this.categoriaId,
    this.categoriaNombre,
  });

  final String id;
  final String nombre;
  final String tipo;
  final bool activo;
  final String? codigo;
  final double? precioUsd;
  final String? categoriaId;
  final String? categoriaNombre;
}

class ProductosPorCategoria {
  const ProductosPorCategoria({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.productos,
  });

  final String categoriaId;
  final String categoriaNombre;
  final List<CatalogoItem> productos;
}

class CreateCatalogoInput {
  const CreateCatalogoInput({
    required this.tipo,
    required this.nombre,
    this.categoriaId,
    this.activo,
    this.codigo,
    this.precioUsd,
  });

  final String tipo;
  final String nombre;
  final String? categoriaId;
  final bool? activo;
  final String? codigo;
  final double? precioUsd;
}

class UpdateCatalogoInput {
  const UpdateCatalogoInput({
    required this.id,
    required this.tipo,
    required this.nombre,
    this.categoriaId,
    this.activo,
    this.codigo,
    this.precioUsd,
  });

  final String id;
  final String tipo;
  final String nombre;
  final String? categoriaId;
  final bool? activo;
  final String? codigo;
  final double? precioUsd;
}

class CatalogosQuery {
  const CatalogosQuery({
    this.search = '',
    this.tipo = 'todos',
    this.page = 1,
    this.limit = 20,
    this.activo,
  });

  final String search;
  final String tipo;
  final int page;
  final int limit;
  final bool? activo;

  CatalogosQuery copyWith({String? search, String? tipo, int? page, int? limit, bool? activo}) {
    return CatalogosQuery(
      search: search ?? this.search,
      tipo: tipo ?? this.tipo,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      activo: activo ?? this.activo,
    );
  }
}

abstract class CatalogosRepository {
  Future<PagedResult<CatalogoItem>> fetchCatalogos({required CatalogosQuery query});

  Future<List<CatalogoItem>> fetchCategorias();

  Future<List<ProductosPorCategoria>> fetchProductosPorCategoria({required String search});

  Future<void> createCatalogo({required CreateCatalogoInput input});

  Future<void> updateCatalogo({required UpdateCatalogoInput input});
}
