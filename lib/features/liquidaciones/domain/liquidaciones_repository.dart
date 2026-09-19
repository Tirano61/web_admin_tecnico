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
    this.tipoSalidaId,
    this.tipoSalidaNombre,
  });

  final String liquidacionId;
  final List<LiquidacionItemDetalle> items;
  final LiquidacionItemsMeta meta;
  final bool remoteEnabled;
  final String? tipoSalidaId;
  final String? tipoSalidaNombre;
}

class LiquidacionItem {
  const LiquidacionItem({
    required this.id,
    required this.servicioId,
    required this.servicioCanal,
    required this.tipoSalidaPrecioUsd,
    required this.km,
    required this.precioKmUsdSnapshotLegacy,
    required this.aprobada,
    required this.liquidadaPago,
    this.estado,
    this.motivoReapertura,
    this.fechaReapertura,
    this.fechaLiquidadaPago,
    this.tecnicoId,
    this.tecnicoNombre,
    this.tecnicoEmail,
    this.clienteNombre,
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
  final String? clienteNombre;
  final String? tipoSalidaId;
  final String? tipoSalidaNombre;
  final double tipoSalidaPrecioUsd;
  final int km;
  final double precioKmUsdSnapshotLegacy;
  final bool aprobada;
  final bool liquidadaPago;
  final String? estado;

  /// Motivo de la ultima reapertura. El backend lo limpia al volver a aprobar.
  final String? motivoReapertura;
  final String? fechaReapertura;
  final String? fechaLiquidadaPago;
  final String? fechaAprobacion;
  final String? createdAt;

  String get estadoNormalizado {
    final normalized = (estado ?? '').trim().toLowerCase();
    if (normalized == 'pendiente' ||
        normalized == 'aprobada' ||
        normalized == 'reabierta' ||
        normalized == 'creada' ||
        normalized == 'borrador' ||
        normalized == 'draft') {
      return normalized;
    }
    return aprobada ? 'aprobada' : 'pendiente';
  }

  bool get isPendiente =>
      estadoNormalizado == 'pendiente' ||
      estadoNormalizado == 'creada' ||
      estadoNormalizado == 'borrador' ||
      estadoNormalizado == 'draft';

  bool get isAprobadaEstado => estadoNormalizado == 'aprobada';

  bool get isReabierta => estadoNormalizado == 'reabierta';

  bool get isEditable => !liquidadaPago && (isPendiente || isReabierta);

  bool get isPassedToPayment => liquidadaPago;

  /// Copia el item cambiando solo el cliente, que es lo unico que aporta la
  /// hidratacion contra `GET /servicios/:id`.
  ///
  /// Reconstruir el item campo por campo en la capa data hacia que cada campo
  /// nuevo (por ejemplo el motivo de reapertura) se perdiera al hidratar.
  LiquidacionItem conClienteNombre(String clienteNombre) {
    return LiquidacionItem(
      id: id,
      servicioId: servicioId,
      servicioCanal: servicioCanal,
      tecnicoId: tecnicoId,
      tecnicoNombre: tecnicoNombre,
      tecnicoEmail: tecnicoEmail,
      clienteNombre: clienteNombre,
      tipoSalidaId: tipoSalidaId,
      tipoSalidaNombre: tipoSalidaNombre,
      tipoSalidaPrecioUsd: tipoSalidaPrecioUsd,
      km: km,
      precioKmUsdSnapshotLegacy: precioKmUsdSnapshotLegacy,
      aprobada: aprobada,
      liquidadaPago: liquidadaPago,
      estado: estado,
      motivoReapertura: motivoReapertura,
      fechaReapertura: fechaReapertura,
      fechaLiquidadaPago: fechaLiquidadaPago,
      fechaAprobacion: fechaAprobacion,
      createdAt: createdAt,
    );
  }

  /// Reabrir deja `aprobado=false`, `fechaAprobacion=null` y saca la
  /// liquidacion de `GET /liquidaciones/para-pago`, del resumen de pago y de
  /// `PATCH /liquidaciones/marcar-pagadas` hasta que se vuelva a aprobar.
  bool get isElegibleParaPago => aprobada && !liquidadaPago && !isReabierta;
}

class ResumenPagoPreviewQuery {
  const ResumenPagoPreviewQuery({
    required this.tecnicoId,
    required this.desde,
    required this.hasta,
  });

  final String tecnicoId;
  final String desde;
  final String hasta;
}

class ConfirmarResumenPagoInput {
  const ConfirmarResumenPagoInput({
    required this.tecnicoId,
    required this.desde,
    required this.hasta,
    required this.liquidacionIds,
  });

  final String tecnicoId;
  final String desde;
  final String hasta;
  final List<String> liquidacionIds;
}

class ResumenPagoPreviewItem {
  const ResumenPagoPreviewItem({
    required this.id,
    required this.servicioId,
    this.fechaAprobacion,
    this.subtotalSalidaUsd,
    this.subtotalItemsUsd,
    required this.totalLiquidacionUsd,
    this.clienteNombre,
    this.fechaHoraServicio,
    this.tipoSalidaNombre,
  });

  final String id;
  final String servicioId;
  final String? fechaAprobacion;
  final double? subtotalSalidaUsd;
  final double? subtotalItemsUsd;
  final double totalLiquidacionUsd;

  // El endpoint de preview no manda cliente, fecha del servicio ni tipo de
  // salida: los hidrata la capa data desde GET /liquidaciones y, como fallback
  // para el cliente, GET /servicios/:id. Quedan null si eso no se resuelve.
  final String? clienteNombre;
  final String? fechaHoraServicio;
  final String? tipoSalidaNombre;

  ResumenPagoPreviewItem copyWith({
    String? clienteNombre,
    String? fechaHoraServicio,
    String? tipoSalidaNombre,
  }) {
    return ResumenPagoPreviewItem(
      id: id,
      servicioId: servicioId,
      fechaAprobacion: fechaAprobacion,
      subtotalSalidaUsd: subtotalSalidaUsd,
      subtotalItemsUsd: subtotalItemsUsd,
      totalLiquidacionUsd: totalLiquidacionUsd,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      fechaHoraServicio: fechaHoraServicio ?? this.fechaHoraServicio,
      tipoSalidaNombre: tipoSalidaNombre ?? this.tipoSalidaNombre,
    );
  }
}

class ResumenPagoPreviewMeta {
  const ResumenPagoPreviewMeta({
    required this.totalLiquidaciones,
    required this.totalResumenUsd,
  });

  final int totalLiquidaciones;
  final double totalResumenUsd;
}

class ResumenPagoConfirmacion {
  const ResumenPagoConfirmacion({
    required this.updated,
    this.resumenPagoId,
    this.fechaLiquidadaPago,
  });

  final int updated;
  final String? resumenPagoId;
  final String? fechaLiquidadaPago;
}

class ResumenPagoPreviewResponse {
  const ResumenPagoPreviewResponse({
    required this.items,
    required this.meta,
    this.confirmacion,
  });

  final List<ResumenPagoPreviewItem> items;
  final ResumenPagoPreviewMeta meta;
  final ResumenPagoConfirmacion? confirmacion;
}

class ResumenesPagoQuery {
  const ResumenesPagoQuery({
    this.tecnicoId,
    this.desde,
    this.hasta,
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final String? desde;
  final String? hasta;
  final int page;
  final int limit;
}

class ResumenPagoHistorialItem {
  const ResumenPagoHistorialItem({
    required this.id,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.desde,
    required this.hasta,
    required this.totalLiquidaciones,
    required this.totalUsdSnapshot,
    required this.createdAt,
  });

  final String id;
  final String tecnicoId;
  final String tecnicoNombre;
  final String desde;
  final String hasta;
  final int totalLiquidaciones;
  final double totalUsdSnapshot;
  final String createdAt;
}

class UltimoResumenPagoItem {
  const UltimoResumenPagoItem({
    required this.id,
    required this.desde,
    required this.hasta,
    required this.totalLiquidaciones,
    required this.totalUsdSnapshot,
    required this.createdAt,
  });

  final String id;
  final String desde;
  final String hasta;
  final int totalLiquidaciones;
  final double totalUsdSnapshot;
  final String createdAt;
}

class TecnicoListadoItem {
  const TecnicoListadoItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String email;
  final bool isActive;
}

class TecnicosListadoQuery {
  const TecnicosListadoQuery({
    this.page = 1,
    this.limit = 20,
    this.q,
    this.activos = true,
  });

  final int page;
  final int limit;
  final String? q;
  final bool activos;
}

class ResumenPagoDetalleItem {
  const ResumenPagoDetalleItem({
    required this.id,
    required this.liquidacionId,
    required this.servicioId,
    this.fechaAprobacionSnapshot,
    this.subtotalSalidaUsdSnapshot,
    this.subtotalItemsUsdSnapshot,
    required this.totalLiquidacionUsdSnapshot,
    this.clienteNombre,
    this.fechaHoraServicio,
    this.tipoSalidaNombre,
  });

  final String id;
  final String liquidacionId;
  final String servicioId;
  final String? fechaAprobacionSnapshot;
  final double? subtotalSalidaUsdSnapshot;
  final double? subtotalItemsUsdSnapshot;
  final double totalLiquidacionUsdSnapshot;

  // Hidratados igual que en el preview.
  final String? clienteNombre;
  final String? fechaHoraServicio;
  final String? tipoSalidaNombre;

  ResumenPagoDetalleItem copyWith({
    String? clienteNombre,
    String? fechaHoraServicio,
    String? tipoSalidaNombre,
  }) {
    return ResumenPagoDetalleItem(
      id: id,
      liquidacionId: liquidacionId,
      servicioId: servicioId,
      fechaAprobacionSnapshot: fechaAprobacionSnapshot,
      subtotalSalidaUsdSnapshot: subtotalSalidaUsdSnapshot,
      subtotalItemsUsdSnapshot: subtotalItemsUsdSnapshot,
      totalLiquidacionUsdSnapshot: totalLiquidacionUsdSnapshot,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      fechaHoraServicio: fechaHoraServicio ?? this.fechaHoraServicio,
      tipoSalidaNombre: tipoSalidaNombre ?? this.tipoSalidaNombre,
    );
  }
}

class ResumenPagoDetalleResponse {
  const ResumenPagoDetalleResponse({
    required this.id,
    required this.tecnicoId,
    required this.tecnicoNombre,
    required this.tecnicoEmail,
    required this.desde,
    required this.hasta,
    required this.totalLiquidaciones,
    required this.totalUsdSnapshot,
    required this.createdByNombre,
    required this.createdAt,
    required this.detalles,
  });

  final String id;
  final String tecnicoId;
  final String tecnicoNombre;
  final String tecnicoEmail;
  final String desde;
  final String hasta;
  final int totalLiquidaciones;
  final double totalUsdSnapshot;
  final String createdByNombre;
  final String createdAt;
  final List<ResumenPagoDetalleItem> detalles;
}

class LiquidacionReaperturaItem {
  const LiquidacionReaperturaItem({
    required this.id,
    required this.motivo,
    required this.fecha,
  });

  final String id;
  final String motivo;
  final String fecha;
}

class LiquidacionReaperturasResponse {
  const LiquidacionReaperturasResponse({
    required this.liquidacionId,
    required this.reaperturas,
    required this.total,
  });

  final String liquidacionId;
  final List<LiquidacionReaperturaItem> reaperturas;
  final int total;
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

class ReopenLiquidacionInput {
  const ReopenLiquidacionInput({
    required this.liquidacionId,
    required this.motivo,
  });

  final String liquidacionId;
  final String motivo;
}

/// Valores que acepta `GET /liquidaciones?estado=`.
///
/// Desde que reabrir deja `estado=reabierta` con `aprobado=false`, filtrar por
/// `aprobado` mezcla reabiertas con pendientes: el panel filtra por estado.
enum LiquidacionEstadoFiltro {
  todas,
  pendiente,
  aprobada,
  reabierta;

  /// `null` para `todas`: no se manda el parametro.
  String? get queryValue => this == LiquidacionEstadoFiltro.todas ? null : name;

  String get etiqueta {
    switch (this) {
      case LiquidacionEstadoFiltro.todas:
        return 'TODAS';
      case LiquidacionEstadoFiltro.pendiente:
        return 'PENDIENTES';
      case LiquidacionEstadoFiltro.aprobada:
        return 'APROBADAS';
      case LiquidacionEstadoFiltro.reabierta:
        return 'REABIERTAS';
    }
  }

  static LiquidacionEstadoFiltro desdeQueryValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    for (final filtro in LiquidacionEstadoFiltro.values) {
      if (filtro.name == normalized) {
        return filtro;
      }
    }
    return LiquidacionEstadoFiltro.todas;
  }
}

const Object _aprobadoNoChange = Object();

class LiquidacionesQuery {
  const LiquidacionesQuery({
    this.tecnicoId,
    this.aprobado,
    this.estado,
    this.liquidadaPago,
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final bool? aprobado;
  final String? estado;
  final bool? liquidadaPago;
  final int page;
  final int limit;

  LiquidacionesQuery copyWith({
    String? tecnicoId,
    Object? aprobado = _aprobadoNoChange,
    String? estado,
    Object? liquidadaPago = _aprobadoNoChange,
    int? page,
    int? limit,
  }) {
    return LiquidacionesQuery(
      tecnicoId: tecnicoId ?? this.tecnicoId,
      aprobado: identical(aprobado, _aprobadoNoChange)
          ? this.aprobado
          : aprobado as bool?,
      estado: estado ?? this.estado,
      liquidadaPago: identical(liquidadaPago, _aprobadoNoChange)
          ? this.liquidadaPago
          : liquidadaPago as bool?,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class LiquidacionesPendientesQuery {
  const LiquidacionesPendientesQuery({
    this.tecnicoId,
    this.estado = 'pendiente',
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final String? estado;
  final int page;
  final int limit;

  LiquidacionesPendientesQuery copyWith({
    String? tecnicoId,
    String? estado,
    int? page,
    int? limit,
  }) {
    return LiquidacionesPendientesQuery(
      tecnicoId: tecnicoId ?? this.tecnicoId,
      estado: estado ?? this.estado,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
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

  Future<void> reopenLiquidacion({required ReopenLiquidacionInput input});

  Future<LiquidacionReaperturasResponse> fetchLiquidacionReaperturas(String liquidacionId);

  Future<LiquidacionItemDetalle?> addLiquidacionItem({required AddLiquidacionItemInput input});

  Future<void> approveLiquidacionItem({required ApproveLiquidacionItemInput input});

  Future<void> deleteLiquidacionItem({required DeleteLiquidacionItemInput input});

  Future<void> createTipoSalida({required CreateTipoSalidaInput input});

  Future<void> updateTipoSalida({required UpdateTipoSalidaInput input});

  Future<void> createTipoServicio({required CreateTipoServicioInput input});

  Future<void> updateTipoServicio({required UpdateTipoServicioInput input});

  Future<ResumenPagoPreviewResponse> fetchResumenPagoPreview({
    required ResumenPagoPreviewQuery query,
  });

  Future<ResumenPagoPreviewResponse> confirmarResumenPago({
    required ConfirmarResumenPagoInput input,
  });

  Future<PagedResult<ResumenPagoHistorialItem>> fetchResumenesPago({
    required ResumenesPagoQuery query,
  });

  Future<PagedResult<TecnicoListadoItem>> fetchTecnicosListado({
    required TecnicosListadoQuery query,
  });

  Future<UltimoResumenPagoItem?> fetchUltimoResumenPago(String tecnicoId);

  Future<ResumenPagoDetalleResponse> fetchResumenPagoDetalle(String resumenId);
}
