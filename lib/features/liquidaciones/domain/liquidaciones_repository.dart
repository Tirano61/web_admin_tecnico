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
  });

  final String id;
  final String servicioId;
  final String? fechaAprobacion;
  final double? subtotalSalidaUsd;
  final double? subtotalItemsUsd;
  final double totalLiquidacionUsd;
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
  });

  final String id;
  final String liquidacionId;
  final String servicioId;
  final String? fechaAprobacionSnapshot;
  final double? subtotalSalidaUsdSnapshot;
  final double? subtotalItemsUsdSnapshot;
  final double totalLiquidacionUsdSnapshot;
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

const Object _aprobadoNoChange = Object();

class LiquidacionesQuery {
  const LiquidacionesQuery({
    this.tecnicoId,
    this.aprobado,
    this.estado,
    this.page = 1,
    this.limit = 20,
  });

  final String? tecnicoId;
  final bool? aprobado;
  final String? estado;
  final int page;
  final int limit;

  LiquidacionesQuery copyWith({
    String? tecnicoId,
    Object? aprobado = _aprobadoNoChange,
    String? estado,
    int? page,
    int? limit,
  }) {
    return LiquidacionesQuery(
      tecnicoId: tecnicoId ?? this.tecnicoId,
      aprobado: identical(aprobado, _aprobadoNoChange)
          ? this.aprobado
          : aprobado as bool?,
      estado: estado ?? this.estado,
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
