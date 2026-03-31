class CatalogoItem {
  const CatalogoItem({required this.id, required this.nombre, required this.tipo});

  final String id;
  final String nombre;
  final String tipo;
}

abstract class CatalogosRepository {
  Future<List<CatalogoItem>> fetchCatalogos();
}
