import 'package:web_admin_tecnico/core/api/paged_result.dart';

class LiquidacionCatalogoItem {
  const LiquidacionCatalogoItem({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

class LiquidacionItemDetalle {
  const LiquidacionItemDetalle({
    required this.id,
    required this.tipoServicioId,
    required this.tipoServicioNombre,
    required this.precioUsdSnapshot,
    required this.aprobado,
    this.fechaAprobacion,
    this.createdAt,
  });

  final String id;
  final String tipoServicioId;
  final String tipoServicioNombre;
  final double precioUsdSnapshot;
  final bool aprobado;
  final String? fechaAprobacion;
  final String? createdAt;
}

class LiquidacionItemsMeta {
  const LiquidacionItemsMeta({
    required this.totalItems,
    required this.aprobados,
    required this.pendientes,
    required this.subtotalUsdTotal,
  });

  final int totalItems;
  final int aprobados;
  final int pendientes;
  final double subtotalUsdTotal;
}

class LiquidacionItemsResponse {
  const LiquidacionItemsResponse({
    required this.liquidacionId,
    required this.items,
    required this.meta,
  });

  final String liquidacionId;
  final List<LiquidacionItemDetalle> items;
  final LiquidacionItemsMeta meta;
}

class LiquidacionItem {
  const LiquidacionItem({
    required this.id,
    required this.servicioId,
    required this.montoUsd,
    required this.aprobada,
    this.estado,
  });

  final String id;
  final String servicioId;
  final double montoUsd;
  final bool aprobada;
  final String? estado;
}

class CreateLiquidacionInput {
  const CreateLiquidacionInput({
    required this.servicioId,
    required this.km,
  });

  final String servicioId;
  final int km;
}

class UpdateLiquidacionInput {
  const UpdateLiquidacionInput({
    required this.liquidacionId,
    required this.tipoSalidaId,
  });

  final String liquidacionId;
  final String tipoSalidaId;
}

class AddLiquidacionItemInput {
  const AddLiquidacionItemInput({
    required this.liquidacionId,
    required this.tipoServicioId,
  });

  final String liquidacionId;
  final String tipoServicioId;
}

class ApproveLiquidacionItemInput {
  const ApproveLiquidacionItemInput({
    required this.liquidacionId,
    required this.itemId,
  });

  final String liquidacionId;
  final String itemId;
}

class DeleteLiquidacionItemInput {
  const DeleteLiquidacionItemInput({
    required this.liquidacionId,
    required this.itemId,
  });

  final String liquidacionId;
  final String itemId;
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

  Future<LiquidacionItemsResponse> fetchLiquidacionItems(String liquidacionId);

  Future<List<LiquidacionCatalogoItem>> fetchTiposSalida();

  Future<List<LiquidacionCatalogoItem>> fetchTiposServicio();

  Future<void> createLiquidacion({required CreateLiquidacionInput input});

  Future<void> updateLiquidacion({required UpdateLiquidacionInput input});

  Future<void> approveLiquidacion(String liquidacionId);

  Future<void> addLiquidacionItem({required AddLiquidacionItemInput input});

  Future<void> approveLiquidacionItem({required ApproveLiquidacionItemInput input});

  Future<void> deleteLiquidacionItem({required DeleteLiquidacionItemInput input});
}
