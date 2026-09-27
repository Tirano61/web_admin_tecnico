/// Parametros de las metricas del Dashboard. Todo sale de endpoints que el
/// panel ya consume; el backend no tiene un endpoint de estadisticas propio
/// para el admin-tecnico (los `/stats/*` son del panel de feedback).
class DashboardQuery {
  const DashboardQuery({
    required this.inicioMes,
    required this.limiteAntiguedadPendientes,
    required this.diasAlertaPendientes,
  });

  /// Arma el periodo actual: servicios desde el dia 1 del mes (hora local) y
  /// pendientes "viejas" las creadas hace mas de [diasAlertaPendientes] dias.
  factory DashboardQuery.paraFecha(
    DateTime ahora, {
    int diasAlertaPendientes = diasAlertaPendientesPorDefecto,
  }) {
    return DashboardQuery(
      inicioMes: DateTime(ahora.year, ahora.month),
      limiteAntiguedadPendientes: ahora.subtract(Duration(days: diasAlertaPendientes)),
      diasAlertaPendientes: diasAlertaPendientes,
    );
  }

  static const int diasAlertaPendientesPorDefecto = 7;

  final DateTime inicioMes;
  final DateTime limiteAntiguedadPendientes;
  final int diasAlertaPendientes;
}

class ServiciosMesMetrica {
  const ServiciosMesMetrica({
    required this.total,
    required this.campo,
    required this.remoto,
    required this.fabrica,
  });

  final int total;
  final int campo;
  final int remoto;
  final int fabrica;
}

class LiquidacionesPendientesMetrica {
  const LiquidacionesPendientesMetrica({
    required this.total,
    required this.antiguas,
  });

  final int total;

  /// Pendientes con `createdAt` anterior a `limiteAntiguedadPendientes`.
  final int antiguas;
}

/// Cada metrica es nullable: si un endpoint falla, el resto del Dashboard se
/// sigue mostrando y esa tarjeta queda sin dato.
class DashboardMetricas {
  const DashboardMetricas({
    required this.diasAlertaPendientes,
    this.serviciosMes,
    this.liquidacionesPendientes,
    this.liquidacionesReabiertas,
    this.liquidacionesParaPago,
    this.tecnicosActivos,
  });

  final int diasAlertaPendientes;
  final ServiciosMesMetrica? serviciosMes;
  final LiquidacionesPendientesMetrica? liquidacionesPendientes;
  final int? liquidacionesReabiertas;
  final int? liquidacionesParaPago;
  final int? tecnicosActivos;

  int get pendientesAntiguas => liquidacionesPendientes?.antiguas ?? 0;

  int get reabiertas => liquidacionesReabiertas ?? 0;

  /// Lo primero que el admin tiene que ver al entrar: reabiertas (salieron del
  /// circuito de pago) o pendientes que llevan demasiados dias sin revisar.
  bool get requiereAtencion => reabiertas > 0 || pendientesAntiguas > 0;

  bool get sinDatos =>
      serviciosMes == null &&
      liquidacionesPendientes == null &&
      liquidacionesReabiertas == null &&
      liquidacionesParaPago == null &&
      tecnicosActivos == null;
}

abstract class DashboardRepository {
  Future<DashboardMetricas> fetchMetricas({required DashboardQuery query});
}
