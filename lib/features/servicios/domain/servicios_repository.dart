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

class ServicioDetalle {
  const ServicioDetalle({
    required this.id,
    required this.estadoOrden,
    required this.canal,
    this.clienteNombre,
    this.lugar,
    this.equipoSerie,
    this.sintoma,
    this.diagnosticoDetalle,
    this.observaciones,
    this.fechaHoraServicio,
    this.facturacion,
    this.facturacionItems = const <ServicioFacturacionItem>[],
  });

  final String id;
  final String estadoOrden;
  final String canal;
  final String? clienteNombre;
  final String? lugar;
  final String? equipoSerie;
  final String? sintoma;
  final String? diagnosticoDetalle;
  final String? observaciones;
  final String? fechaHoraServicio;
  final ServicioFacturacionResumen? facturacion;
  final List<ServicioFacturacionItem> facturacionItems;
}

class ServicioFacturacionResumen {
  const ServicioFacturacionResumen({
    this.cotizacionDolarSnapshot,
    this.valorKmUsdSnapshot,
    this.subtotalKmUsd,
    this.subtotalKmArs,
    this.subtotalGeneralUsd,
    this.subtotalGeneralArs,
    this.ivaPorcentaje,
    this.totalConIvaArs,
    this.descuentoPorcentaje,
    this.totalFinalArs,
  });

  final double? cotizacionDolarSnapshot;
  final double? valorKmUsdSnapshot;
  final double? subtotalKmUsd;
  final double? subtotalKmArs;
  final double? subtotalGeneralUsd;
  final double? subtotalGeneralArs;
  final double? ivaPorcentaje;
  final double? totalConIvaArs;
  final double? descuentoPorcentaje;
  final double? totalFinalArs;
}

class ServicioFacturacionItem {
  const ServicioFacturacionItem({
    required this.tipoItem,
    required this.descripcion,
    this.cantidad,
    this.subtotalUsd,
    this.subtotalArs,
  });

  final String tipoItem;
  final String descripcion;
  final double? cantidad;
  final double? subtotalUsd;
  final double? subtotalArs;
}

class ServicioDocumentoInfo {
  const ServicioDocumentoInfo({
    this.pdfHashSha256,
    this.pdfUrl,
    this.firmaClienteNombre,
    this.firmaClienteDocumento,
    this.firmaFechaHora,
  });

  final String? pdfHashSha256;
  final String? pdfUrl;
  final String? firmaClienteNombre;
  final String? firmaClienteDocumento;
  final String? firmaFechaHora;
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

  Future<ServicioDetalle> fetchServicioDetalle(String servicioId);

  Future<ServicioDocumentoInfo> fetchDocumento(String servicioId);

  Future<List<int>> fetchDocumentoPdfBytes(String servicioId);
}
