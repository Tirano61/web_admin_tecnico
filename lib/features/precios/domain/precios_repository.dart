import 'package:web_admin_tecnico/core/api/paged_result.dart';

class PrecioItem {
  const PrecioItem({required this.id, required this.descripcion, required this.valor});

  final String id;
  final String descripcion;
  final double valor;
}

class PreciosQuery {
  const PreciosQuery({
    this.search = '',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final int page;
  final int limit;

  PreciosQuery copyWith({String? search, int? page, int? limit}) {
    return PreciosQuery(
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

abstract class PreciosRepository {
  Future<PagedResult<PrecioItem>> fetchPrecios({required PreciosQuery query});
}
