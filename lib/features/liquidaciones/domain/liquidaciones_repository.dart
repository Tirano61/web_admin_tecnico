import 'package:web_admin_tecnico/core/api/paged_result.dart';

class TipoSalidaCatalogoItem {
  const TipoSalidaCatalogoItem({
    required this.id,
    required this.nombre,
    required this.precioUsd,
    this.kmHasta,
    this.activo = true,
  });

  final String id;
  final String nombre;
  final int? kmHasta;
  final double precioUsd;
  final bool activo;
}

class TipoServicioCatalogoItem {
  const TipoServicioCatalogoItem({
    required this.id,
    required this.nombre,
    required this.precioUsd,
    this.activo = true,
  });

  final String id;
  final String nombre;
  final double precioUsd;
  final bool activo;
}

class LiquidacionItemDetalle {
  const LiquidacionItemDetalle({
    required this.id,
    required this.tipoServicioId,
    required this.tipoServicioNombre,
    required this.precioUsdSnapshot,
    required this.aprobado,
    this.isPersisted = true,
    this.fechaAprobacion,
    this.createdAt,
  });

  final String id;
  final String tipoServicioId;
  final String tipoServicioNombre;
  final double precioUsdSnapshot;
  final bool aprobado;
  final bool isPersisted;
  final String? fechaAprobacion;
  final String? createdAt;

  LiquidacionItemDetalle copyWith({
    String? id,
    String? tipoServicioId,
    String? tipoServicioNombre,
    double? precioUsdSnapshot,
    bool? aprobado,
    bool? isPersisted,
    String? fechaAprobacion,
    String? createdAt,
  }) {
    return LiquidacionItemDetalle(
      id: id ?? this.id,
      tipoServicioId: tipoServicioId ?? this.tipoServicioId,
      tipoServicioNombre: tipoServicioNombre ?? this.tipoServicioNombre,
      precioUsdSnapshot: precioUsdSnapshot ?? this.precioUsdSnapshot,
      aprobado: aprobado ?? this.aprobado,
      isPersisted: isPersisted ?? this.isPersisted,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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
    required this.remoteEnabled,
  });

  final String liquidacionId;
  final List<LiquidacionItemDetalle> items;
  final LiquidacionItemsMeta meta;
  final bool remoteEnabled;
}

class LiquidacionItem {
  const LiquidacionItem({
    required this.id,
    required this.servicioId,
    required this.servicioCanal,
    required this.tipoSalidaPrecioUsd,
    required this.km,
    required this.precioKmUsdSnapshot,
    required this.aprobada,
    this.tecnicoId,
    this.tecnicoNombre,
    this.tecnicoEmail,
    this.tipoSalidaId,
    this.tipoSalidaNombre,
    this.fechaAprobacion,
    this.createdAt,
  });

  final String id;
  final String servicioId;
  final String servicioCanal;
  final String? tecnicoId;
  final String? tecnicoNombre;
  final String? tecnicoEmail;
  final String? tipoSalidaId;
  final String? tipoSalidaNombre;
  final double tipoSalidaPrecioUsd;
  final int km;
  final double precioKmUsdSnapshot;
  final bool aprobada;
  final String? fechaAprobacion;
  final String? createdAt;

  double get subtotalEstimadoUsd => tipoSalidaPrecioUsd + (km * precioKmUsdSnapshot);
}

class LiquidacionPendienteItem {
  const LiquidacionPendienteItem({
    required this.servicioId,
    required this.servicioCanal,
    this.kmSugerido,
    this.tecnicoId,
    this.tecnicoNombre,
    this.tecnicoEmail,
    this.clienteNombre,
    this.fechaHoraServicio,
  });

  final String servicioId;
  final String servicioCanal;
  final int? kmSugerido;
  final String? tecnicoId;
  final String? tecnicoNombre;
  final String? tecnicoEmail;
  final String? clienteNombre;
  final String? fechaHoraServicio;
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

class CreateTipoSalidaInput {
  const CreateTipoSalidaInput({
    required this.nombre,
    required this.precioUsd,
    this.kmHasta,
  });

  final String nombre;
  final int? kmHasta;
  final double precioUsd;
}

class UpdateTipoSalidaInput {
  const UpdateTipoSalidaInput({
    required this.id,
    this.nombre,
    this.kmHasta,
    this.precioUsd,
    this.activo,
  });

  final String id;
  final String? nombre;
  final int? kmHasta;
  final double? precioUsd;
  final bool? activo;
}

class CreateTipoServicioInput {
  const CreateTipoServicioInput({
    required this.nombre,
    required this.precioUsd,
  });

  final String nombre;
  final double precioUsd;
}

class UpdateTipoServicioInput {
  const UpdateTipoServicioInput({
    required this.id,
    this.nombre,
    this.precioUsd,
    this.activo,
  });

  final String id;
  final String? nombre;
  final double? precioUsd;
  final bool? activo;
}

const Object _aprobadoNoChange = Object();

class LiquidacionesQuery {
  const LiquidacionesQuery({
    this.tecnicoId,
    this.aprobado,
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final bool? aprobado;
  final int page;
  final int limit;

  LiquidacionesQuery copyWith({
    String? tecnicoId,
    Object? aprobado = _aprobadoNoChange,
    int? page,
    int? limit,
  }) {
    return LiquidacionesQuery(
      tecnicoId: tecnicoId ?? this.tecnicoId,
      aprobado: identical(aprobado, _aprobadoNoChange)
          ? this.aprobado
          : aprobado as bool?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class LiquidacionesPendientesQuery {
  const LiquidacionesPendientesQuery({
    this.tecnicoId,
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final int page;
  final int limit;
}

abstract class LiquidacionesRepository {
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({required LiquidacionesQuery query});

  Future<PagedResult<LiquidacionPendienteItem>> fetchLiquidacionesPendientes({
    required LiquidacionesPendientesQuery query,
  });

  Future<LiquidacionItemsResponse?> fetchLiquidacionItems(String liquidacionId);

  Future<List<TipoSalidaCatalogoItem>> fetchTiposSalida();

  Future<List<TipoServicioCatalogoItem>> fetchTiposServicio();

  Future<void> createLiquidacion({required CreateLiquidacionInput input});

  Future<void> updateLiquidacion({required UpdateLiquidacionInput input});

  Future<void> approveLiquidacion(String liquidacionId);

  Future<LiquidacionItemDetalle?> addLiquidacionItem({required AddLiquidacionItemInput input});

  Future<void> approveLiquidacionItem({required ApproveLiquidacionItemInput input});

  Future<void> deleteLiquidacionItem({required DeleteLiquidacionItemInput input});

  Future<void> createTipoSalida({required CreateTipoSalidaInput input});

  Future<void> updateTipoSalida({required UpdateTipoSalidaInput input});

  Future<void> createTipoServicio({required CreateTipoServicioInput input});

  Future<void> updateTipoServicio({required UpdateTipoServicioInput input});
}
