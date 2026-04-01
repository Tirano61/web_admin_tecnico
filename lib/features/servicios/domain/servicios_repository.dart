import 'package:web_admin_tecnico/core/api/paged_result.dart';

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

class ServiciosQuery {
  const ServiciosQuery({
    this.search = '',
    this.estado = 'todos',
    this.canal = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String estado;
  final String canal;
  final int page;
  final int limit;

  ServiciosQuery copyWith({
    String? search,
    String? estado,
    String? canal,
    int? page,
    int? limit,
  }) {
    return ServiciosQuery(
      search: search ?? this.search,
      estado: estado ?? this.estado,
      canal: canal ?? this.canal,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

abstract class ServiciosRepository {
  Future<PagedResult<ServicioItem>> fetchServicios({required ServiciosQuery query});
}
