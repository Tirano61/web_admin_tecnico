import 'package:web_admin_tecnico/core/api/paged_result.dart';

class ServicioItem {
  const ServicioItem({
    required this.id,
    required this.descripcion,
    required this.estadoOrden,
    this.canal,
    this.fechaHoraServicio,
    this.equipoSerie,
    this.equipoModelo,
  });

  final String id;
  final String descripcion;
  final String estadoOrden;
  final String? canal;
  final String? fechaHoraServicio;
  final String? equipoSerie;
  final String? equipoModelo;
}

class ServicioDetalle {
  const ServicioDetalle({
    required this.id,
    required this.estadoOrden,
    required this.canal,
    this.clienteNombre,
    this.lugar,
    this.equipoSerie,
    this.equipoModelo,
    this.equipoAnio,
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
  final String? equipoModelo;
  final int? equipoAnio;
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

class ServicioTecnicoOption {
  const ServicioTecnicoOption({
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

// Los filtros del backend (FilterServiciosDto) son canal y tecnicoId; no hay
// busqueda por texto ni filtro por estado de orden.
class ServiciosQuery {
  const ServiciosQuery({
    this.canal = 'todos',
    this.tecnicoId = 'todos',
    this.page = 1,
    this.limit = 6,
  });

  final String canal;
  final String tecnicoId;
  final int page;
  final int limit;

  ServiciosQuery copyWith({
    String? canal,
    String? tecnicoId,
    int? page,
    int? limit,
  }) {
    return ServiciosQuery(
      canal: canal ?? this.canal,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

abstract class ServiciosRepository {
  Future<PagedResult<ServicioItem>> fetchServicios({required ServiciosQuery query});

  Future<List<ServicioTecnicoOption>> fetchTecnicosFiltro();

  Future<ServicioDetalle> fetchServicioDetalle(String servicioId);

  Future<ServicioDocumentoInfo> fetchDocumento(String servicioId);

  Future<List<int>> fetchDocumentoPdfBytes(String servicioId);
}
