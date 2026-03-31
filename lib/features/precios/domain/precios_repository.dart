class PrecioItem {
  const PrecioItem({required this.id, required this.descripcion, required this.valor});

  final String id;
  final String descripcion;
  final double valor;
}

abstract class PreciosRepository {
  Future<List<PrecioItem>> fetchPrecios();
}
