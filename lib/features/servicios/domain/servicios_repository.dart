class ServicioItem {
  const ServicioItem({
    required this.id,
    required this.descripcion,
    required this.estadoOrden,
  });

  final String id;
  final String descripcion;
  final String estadoOrden;
}

abstract class ServiciosRepository {
  Future<List<ServicioItem>> fetchServicios();
}
