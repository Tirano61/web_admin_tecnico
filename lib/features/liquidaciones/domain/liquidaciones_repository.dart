import 'package:web_admin_tecnico/core/api/paged_result.dart';

class LiquidacionItem {
  const LiquidacionItem({
    required this.id,
    required this.servicioId,
    required this.montoUsd,
    required this.aprobada,
  });

  final String id;
  final String servicioId;
  final double montoUsd;
  final bool aprobada;
}

class LiquidacionesQuery {
  const LiquidacionesQuery({
    this.search = '',
    this.estado = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final String estado;
  final int page;
  final int limit;

  LiquidacionesQuery copyWith({String? search, String? estado, int? page, int? limit}) {
    return LiquidacionesQuery(
      search: search ?? this.search,
      estado: estado ?? this.estado,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

abstract class LiquidacionesRepository {
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({required LiquidacionesQuery query});
}
